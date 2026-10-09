"""
Route Search Service — Dijkstra-based graph search.

The transportation network is modeled as a weighted directed graph:
  - Nodes: stations (identified by station_id)
  - Edges: direct connections between consecutive route stops

Each edge carries:
  - travel_time (minutes) — estimated segment time
  - fare (ETB)
  - route_id

Results are sorted by three deterministic strategies:
  1. Fastest  — total estimated time
  2. Cheapest — total fare
  3. Fewest transfers — number of route changes
"""

import heapq
from typing import List, Optional, Dict, Any, Tuple
from collections import defaultdict

from sqlalchemy.orm import Session

from app.repositories.route_repository import RouteRepository
from app.models.models import Route


class RouteSearchService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = RouteRepository(db)

    # ─── Public API ─────────────────────────────────────────────────────────

    def search(
        self,
        from_station_id: str,
        to_station_id: str,
        sort_by: str = "fastest",   # fastest | cheapest | fewest_transfers
    ) -> List[Dict]:
        """
        Find routes from from_station_id to to_station_id.
        Returns a list of route result dicts, sorted by the requested criterion.
        """
        routes = self.repo.get_all_active_routes()
        graph = self._build_graph(routes)

        if from_station_id == to_station_id:
            return []

        # Check for direct routes (single route with both stations)
        direct = self._find_direct_routes(routes, from_station_id, to_station_id)

        # Check for 1-transfer routes
        one_transfer = self._find_one_transfer_routes(routes, from_station_id, to_station_id)

        all_results = direct + one_transfer

        if not all_results:
            return []

        # Sort
        if sort_by == "cheapest":
            all_results.sort(key=lambda r: r["estimated_fare"])
        elif sort_by == "fewest_transfers":
            all_results.sort(key=lambda r: (r["transfers"], r["estimated_time"]))
        else:  # fastest
            all_results.sort(key=lambda r: r["estimated_time"])

        return all_results

    # ─── Direct Routes ───────────────────────────────────────────────────────

    def _find_direct_routes(
        self, routes: List[Route], from_id: str, to_id: str
    ) -> List[Dict]:
        results = []
        for route in routes:
            stop_ids = [rs.station_id for rs in route.route_stops]
            if from_id in stop_ids and to_id in stop_ids:
                from_idx = stop_ids.index(from_id)
                to_idx = stop_ids.index(to_id)
                if from_idx < to_idx:  # correct direction
                    fare = route.fares[0].amount if route.fares else 0.0
                    results.append(
                        self._make_result(route, transfers=0, fare=fare)
                    )
        return results

    # ─── 1-Transfer Routes ────────────────────────────────────────────────────

    def _find_one_transfer_routes(
        self, routes: List[Route], from_id: str, to_id: str
    ) -> List[Dict]:
        # Build index: station_id → routes containing it
        station_routes: Dict[str, List[Route]] = defaultdict(list)
        for route in routes:
            for rs in route.route_stops:
                station_routes[rs.station_id].append(route)

        # Find routes that contain from_id
        from_routes = station_routes.get(from_id, [])
        # Find routes that contain to_id
        to_routes = station_routes.get(to_id, [])

        results = []
        seen_pairs = set()

        for r1 in from_routes:
            r1_stops = [rs.station_id for rs in r1.route_stops]
            if from_id not in r1_stops:
                continue
            from_idx = r1_stops.index(from_id)

            for r2 in to_routes:
                if r1.id == r2.id:
                    continue
                r2_stops = [rs.station_id for rs in r2.route_stops]
                if to_id not in r2_stops:
                    continue
                to_idx = r2_stops.index(to_id)

                # Find transfer station: must be after from_id in r1, before to_id in r2
                for transfer_sid in r1_stops[from_idx + 1:]:
                    if transfer_sid in r2_stops:
                        t_idx_r2 = r2_stops.index(transfer_sid)
                        if t_idx_r2 < to_idx:
                            key = (r1.id, r2.id, transfer_sid)
                            if key not in seen_pairs:
                                seen_pairs.add(key)
                                fare1 = r1.fares[0].amount if r1.fares else 0.0
                                fare2 = r2.fares[0].amount if r2.fares else 0.0
                                time1 = r1.estimated_time or 20
                                time2 = r2.estimated_time or 20
                                results.append({
                                    "routes": [self._route_to_dict(r1), self._route_to_dict(r2)],
                                    "route": self._route_to_dict(r1),  # primary route shown
                                    "transfers": 1,
                                    "transfer_station_id": transfer_sid,
                                    "estimated_time": time1 + time2,
                                    "estimated_fare": fare1 + fare2,
                                    "is_multi_route": True,
                                })
        return results

    # ─── Helpers ─────────────────────────────────────────────────────────────

    def _build_graph(self, routes: List[Route]) -> Dict:
        """Build adjacency graph for potential future Dijkstra on complex networks."""
        graph = defaultdict(list)
        for route in routes:
            stops = route.route_stops
            for i in range(len(stops) - 1):
                from_s = stops[i].station_id
                to_s = stops[i + 1].station_id
                fare = route.fares[0].amount if route.fares else 0.0
                time_per_stop = (route.estimated_time or 20) / max(len(stops) - 1, 1)
                graph[from_s].append({
                    "to": to_s,
                    "route_id": route.id,
                    "time": time_per_stop,
                    "fare": fare,
                })
        return graph

    def _make_result(self, route: Route, transfers: int, fare: float) -> Dict:
        return {
            "routes": [self._route_to_dict(route)],
            "route": self._route_to_dict(route),
            "transfers": transfers,
            "estimated_time": route.estimated_time or 0,
            "estimated_fare": fare,
            "is_multi_route": False,
        }

    @staticmethod
    def _route_to_dict(route: Route) -> Dict:
        return {
            "id": route.id,
            "name": route.name,
            "city_id": route.city_id,
            "transport_type_id": route.transport_type_id,
            "estimated_time": route.estimated_time,
            "distance": route.distance,
            "operating_hours": route.operating_hours,
            "status": route.status,
            "transport_type": (
                {
                    "id": route.transport_type.id,
                    "name": route.transport_type.name,
                    "icon": route.transport_type.icon,
                    "description": route.transport_type.description,
                    "is_active": route.transport_type.is_active,
                }
                if route.transport_type
                else None
            ),
            "route_stops": [
                {
                    "id": rs.id,
                    "route_id": rs.route_id,
                    "station_id": rs.station_id,
                    "stop_order": rs.stop_order,
                    "station": (
                        {
                            "id": rs.station.id,
                            "name": rs.station.name,
                            "city_id": rs.station.city_id,
                            "latitude": rs.station.latitude,
                            "longitude": rs.station.longitude,
                            "operating_hours": rs.station.operating_hours,
                            "status": rs.station.status,
                            "description": rs.station.description,
                        }
                        if rs.station
                        else None
                    ),
                }
                for rs in route.route_stops
            ],
            "fares": [
                {
                    "id": f.id,
                    "route_id": f.route_id,
                    "transport_type_id": f.transport_type_id,
                    "amount": f.amount,
                    "currency": f.currency,
                }
                for f in route.fares
            ],
        }
