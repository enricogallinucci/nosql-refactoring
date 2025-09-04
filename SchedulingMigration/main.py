import time
import json
import sys
from pathlib import Path
import networkx as nx
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
from tqdm import tqdm


G = nx.DiGraph()
query_frequency_in_workload = 0     # Number of queries per second in the workload


def add_benefit_to_nodes():
    for current in G.nodes:
        node = G.nodes[current]
        if node["kind"] == "Query":
            node["benefit"] = query_frequency_in_workload * node["weight"] * (node["time_before"] - node["time_after"])


def add_cumulative_duration_to_nodes(visited):
    ready = [0]
    while ready != []:
        current = ready.pop()
        if current not in visited:
            cum_dur = G.nodes[current]["duration"]
            for node in G.predecessors(current):
                cum_dur += G.nodes[node]["duration"]
            G.nodes[current]["cumulative_duration"] = cum_dur
            visited.append(current)
        for node in G.successors(current):
            if all([n in visited for n in G.predecessors(node)]):
                ready.append(node)


def annotate_queries_in_migrations():
    ready = [999]
    visited = []
    while ready != []:
        current = ready.pop()
        if G.nodes[current]["kind"] == "Query":
            G.nodes[current]["impacted_queries"] = [current]
        else:
            impacted = []
            for node in G.successors(current):
                impacted.extend(G.nodes[node]["impacted_queries"])
            G.nodes[current]["impacted_queries"] = impacted
            G.nodes[current]["related_benefit"] = sum([G.nodes[n]["benefit"] for n in impacted if G.nodes[n]["benefit"] > 0])
        visited.append(current)
        for node in G.predecessors(current):
            if all([n in visited for n in G.successors(node)]):
                ready.append(node)


def load_graph(file_path) -> None:
    global G
    global query_frequency_in_workload

    # Open and load the JSON file
    with open(file_path, 'r') as f:
        graph_elements = json.load(f)
        nodes = [tuple(item) for item in graph_elements.get('nodes')]
        edges = [tuple(item) for item in graph_elements.get('edges')]
        query_frequency_in_workload = graph_elements.get('query_frequency_in_workload', 0)

    G.add_nodes_from(nodes)
    G.add_edges_from(edges)

    add_benefit_to_nodes()
    annotate_queries_in_migrations()
    # for i in G.nodes:
    #     print(G.nodes[i])


def show_graph():
    shells = [
        [node for node, data in G.nodes(data=True) if data["kind"] == "Query"],
        [node for node, data in G.nodes(data=True) if data["kind"] == "Migration"]
    ]
    labels = {node: data["descr"] for node, data in G.nodes(data=True) if node not in [0, 999]}
    nx.draw_shell(G.subgraph([n for n in G.nodes if n not in [0, 999]]), nlist=shells, labels=labels, with_labels=True, font_weight='bold')
    plt.show()


def get_ready_nodes(nodes, visited) -> list[int]:
    ready = []
    for i in nodes:
        if i not in visited and all([n in visited for n in G.predecessors(i)]):
            ready.append(i)
    return ready


def get_benefit_of_plan(plan) -> float:
    benefit = 0
    enabled = 0
    for i in range(len(plan)):
        if G.nodes[plan[i]]["kind"] == "Query":
            enabled += G.nodes[plan[i]]["benefit"]
        elif G.nodes[plan[i]]["kind"] == "Migration":
            benefit += G.nodes[plan[i]]["duration"]*enabled
    return benefit


def update_enabled_of_plan(nodes: list[int], sign: int):
    global enabled
    for i in nodes:
        enabled += sign * G.nodes[i]["benefit"]


def update_benefit_of_plan(node: int, sign: int):
    global benefit
    global enabled
    benefit += sign * G.nodes[node]["duration"] * enabled


def exhaustive_search(plan, ready, plan_pretail, plan_tail):
    global steps, plans_found
    global benefit
    global best_benefit, best_plan
    global worst_benefit, worst_plan

    steps += 1

    # Add all queries to the plan at once (no need for backtracking)
    ready_queries = [i for i in ready if G.nodes[i]["kind"] == "Query" and G.nodes[i]["benefit"] > 0]
    tail = [i for i in ready if G.nodes[i]["kind"] == "Query" and G.nodes[i]["benefit"] <= 0]
    pretail = [i for i in ready if G.nodes[i]["kind"] == "Migration" and G.successors(i) == [999]]
    plan_tail.extend(tail)
    plan_pretail.extend(pretail)
    plan.extend(ready_queries)
    update_enabled_of_plan(ready_queries, sign=+1)
    # Add migrations one at a time (with backtracking)
    ready_migrations = [i for i in ready if G.nodes[i]["kind"] == "Migration" and i not in plan_pretail]
    if not ready_migrations:
        plan.extend(plan_pretail+plan_tail)
        if benefit > best_benefit:
            best_benefit, best_plan = benefit, plan.copy()
        if benefit < worst_benefit:
            worst_benefit, worst_plan = benefit, plan.copy()
        _ = [plan.pop() for _ in range(len(plan_pretail+plan_tail))]
        # print("Plan found:", plan, benefit)
        plans_found += 1
    else:
        for current in ready_migrations:
            plan.append(current)
            # Increase the benefit of the current migration
            update_benefit_of_plan(current, sign=+1)
            # Add new nodes that became ready
            next_ready = [n for n in ready_migrations if n != current]
            for j in G.successors(current):
                if j not in plan and all([n in plan for n in G.predecessors(j) if n != 0]):
                    next_ready.append(j)
            # Recursive call
            exhaustive_search(plan, next_ready, plan_pretail, plan_tail)
            # Remove the benefit of the current migration
            update_benefit_of_plan(current, sign=-1)
            # Remove the migration node from the plan
            plan.pop()
    # Remove the query nodes from the plan
    update_enabled_of_plan(ready_queries, sign=-1)
    _ = [plan_pretail.pop() for _ in range(len(pretail))]
    _ = [plan_tail.pop() for _ in range(len(tail))]
    _ = [plan.pop() for _ in range(len(ready_queries))]


def get_heuristics_migration_duration(plan, nodes) -> list[int]:
    heuristics = []
    for node in nodes:
        pending_duration = sum([G.nodes[n]["duration"] for n in G.nodes if n != node and n not in plan and G.nodes[n]["kind"] == "Migration"])
        heuristics.append(pending_duration)
    return heuristics


def get_heuristics_query_benefit(plan, nodes) -> list[int]:
    heuristics = []
    for node in nodes:
        heuristics.append(G.nodes[node]["related_benefit"])
    return heuristics


def get_heuristics_without_subtraction(plan, nodes) -> list[int]:
    add_cumulative_duration_to_nodes(plan.copy())
    heuristics = []
    for node in nodes:
        pending_duration = sum([G.nodes[n]["duration"] for n in G.nodes if n != node and n not in plan and G.nodes[n]["kind"] == "Migration"])
        h = 0
        for q in G.nodes[node]["impacted_queries"]:
            if G.nodes[q]["benefit"] > 0:
                h += (pending_duration - G.nodes[q]["cumulative_duration"]) * G.nodes[q]["benefit"] * (G.nodes[node]["duration"] / G.nodes[q]["cumulative_duration"])
        heuristics.append(h)
    #print("Without substraction:", nodes, "->", heuristics)
    return heuristics


def get_heuristics_alltogether(plan, nodes) -> list[int]:
    add_cumulative_duration_to_nodes(plan.copy())
    pending_benefit = sum([G.nodes[n]["benefit"] for n in G.nodes if n not in plan and G.nodes[n]["kind"] == "Query" and G.nodes[n]["benefit"] > 0])
    pending_duration = sum([G.nodes[n]["duration"] for n in G.nodes if n not in plan and G.nodes[n]["kind"] == "Migration"])
    heuristics = []
    for node in nodes:
        h = 0
        for q in G.nodes[node]["impacted_queries"]:
            if G.nodes[q]["benefit"] > 0:
                # The heuristic takes:
                # 1) The maximum duration left after executing all the requirements of a query
                # 2) The benefit of the query
                # 3) The percentage of the requirements that this migration represents
                h += (pending_duration - G.nodes[q]["cumulative_duration"]) * G.nodes[q]["benefit"] * (G.nodes[node]["duration"] / G.nodes[q]["cumulative_duration"])
        # The heuristic subtracts the benefit removed from all the other queries that do not benefit if we do the migration before and not after them
        h -= (pending_benefit - G.nodes[node]["related_benefit"]) * G.nodes[node]["duration"]
        heuristics.append(h)
    #print("All together:", nodes, "->", heuristics)
    return heuristics


def greedy_search(plan, ready, plan_tail, plan_pretail, heuristic_function):
    global steps
    global benefit

    steps += 1

    # Add all queries to the plan at once (no need for backtracking)
    ready_queries = [i for i in ready if G.nodes[i]["kind"] == "Query" and G.nodes[i]["benefit"] > 0]
    tail = [i for i in ready if G.nodes[i]["kind"] == "Query" and G.nodes[i]["benefit"] <= 0]
    pretail = [i for i in ready if G.nodes[i]["kind"] == "Migration" and G.successors(i) == [999]]
    plan_tail.extend(tail)
    plan_pretail.extend(pretail)
    plan.extend(ready_queries)
    update_enabled_of_plan(ready_queries, sign=+1)
    # Take one more migration
    ready_migrations = [i for i in ready if G.nodes[i]["kind"] == "Migration"]
    if not ready_migrations:
        plan.extend(plan_pretail+plan_tail)
        print(f"Greedy plan: {plan} -> {benefit:.2f}")
    else:
        heuristics = heuristic_function(plan, ready_migrations)
        current = ready_migrations[heuristics.index(max(heuristics))]
        plan.append(current)
        # Increase the benefit of the current migration
        update_benefit_of_plan(current, sign=+1)
        # Add new nodes that became ready
        next_ready = [n for n in ready_migrations if n != current]
        for j in G.successors(current):
            if j not in plan and all([n in plan for n in G.predecessors(j) if n != 0]):
                next_ready.append(j)
        # Recursive call
        greedy_search(plan, next_ready, plan_tail, plan_pretail, heuristic_function)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Error: Input filename required as a parameter")
        exit(1)

    load_graph(Path("SchedulingMigration/inputs").joinpath(sys.argv[1]))

    if len(sys.argv) > 2 and sys.argv[2] == "show":
        show_graph()
    else:
        print("============================================================================================ Exhaustive search (can take a while)")
        steps = 0
        plans_found = 0
        benefit = 0
        enabled = 0
        best_benefit = 0
        worst_benefit = 999999999
        best_plan = [0]
        worst_plan = [0]
        start = time.time()
        # The loop is just to track progress. If not needed, next line can be used instead
        # exhaustive_search([], get_ready_nodes(G.nodes, [0]), [], [])
        for node in tqdm(get_ready_nodes(G.nodes, [0])):
            if G.nodes[node]["kind"] != "Migration" or G.successors(node) != [999]:
                update_benefit_of_plan(node, sign=-1)
                exhaustive_search([node], get_ready_nodes(G.nodes, [0, node]), [], [])
                update_benefit_of_plan(node, sign=-1)
        end = time.time()
        print(f"Best plan:   {best_plan} -> {best_benefit:.2f}")
        print(f"Worst plan:  {worst_plan} -> {worst_benefit:.2f}")
        print(f"{steps} search steps executed in {(end - start):.2f} seconds, finding {plans_found} plans")

        print("============================================================================================ Greedy with the smallest migration duration")
        steps = 0
        benefit = 0
        enabled = 0
        start = time.time()
        greedy_search([], ready=get_ready_nodes(G.nodes, visited=[0]), plan_tail=[], plan_pretail=[], heuristic_function=get_heuristics_migration_duration)
        end = time.time()
        print(f"{steps} search steps executed in {(end - start):.2f} seconds")

        print("============================================================================================ Greedy with the highest query benefit")
        steps = 0
        benefit = 0
        enabled = 0
        start = time.time()
        greedy_search([], ready=get_ready_nodes(G.nodes, visited=[0]), plan_tail=[], plan_pretail=[], heuristic_function=get_heuristics_query_benefit)
        end = time.time()
        print(f"{steps} search steps executed in {(end - start):.2f} seconds")

        print("============================================================================================ Greedy with the combination of both and no subtraction")
        steps = 0
        benefit = 0
        enabled = 0
        start = time.time()
        greedy_search([], ready=get_ready_nodes(G.nodes, visited=[0]), plan_tail=[], plan_pretail=[], heuristic_function=get_heuristics_without_subtraction)
        end = time.time()
        print(f"{steps} search steps executed in {(end - start):.2f} seconds")

        print("============================================================================================ Greedy with the combination of both++")
        steps = 0
        benefit = 0
        enabled = 0
        start = time.time()
        greedy_search([], ready=get_ready_nodes(G.nodes, visited=[0]), plan_tail=[], plan_pretail=[], heuristic_function=get_heuristics_alltogether)
        end = time.time()
        print(f"{steps} search steps executed in {(end - start):.2f} seconds")
