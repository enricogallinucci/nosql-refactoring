import time
import json
import sys
from pathlib import Path
import networkx as nx
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt


G = nx.DiGraph()
benefit = 0
enabled = 0
best = 0
worse = 999999999
best_plan = [0]
worse_plan = [0]


def add_benefit_to_nodes():
    for current in G.nodes:
        node = G.nodes[current]
        if node["kind"] == "Query":
            node["benefit"] = node["weight"] * (node["time_before"] - node["time_after"])


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
    ready = [99]
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
        visited.append(current)
        for node in G.predecessors(current):
            if all([n in visited for n in G.successors(node)]):
                ready.append(node)


def load_graph(file_path) -> None:
    global G

    # Open and load the JSON file
    with open(file_path, 'r') as f:
        graph_elements = json.load(f)
        nodes = [tuple(item) for item in graph_elements.get('nodes')]
        edges = [tuple(item) for item in graph_elements.get('edges')]

    G.add_nodes_from(nodes)
    G.add_edges_from(edges)

    add_benefit_to_nodes()
    annotate_queries_in_migrations()
    # for i in G.nodes:
    #     print(G.nodes[i])


def show_graph():
    nx.draw_shell(G, with_labels=True, font_weight='bold')
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


def update_benefit_of_plan(nodes: list[int], sign: int):
    global benefit
    global enabled
    for i in nodes:
        if G.nodes[i]["kind"] == "Query":
            enabled += sign * G.nodes[i]["benefit"]
        elif G.nodes[i]["kind"] == "Migration":
            benefit += sign * G.nodes[i]["duration"] * enabled


def exhaustive_search(plan, ready, plan_tail):
    global steps
    global benefit
    global best, best_plan
    global worse, worse_plan

    steps += 1

    # Add all queries to the plan at once (no need for backtracking)
    ready_queries = [i for i in ready if G.nodes[i]["kind"] == "Query" and G.nodes[i]["benefit"] > 0]
    plan_tail.extend([i for i in ready if G.nodes[i]["kind"] == "Query" and G.nodes[i]["benefit"] <= 0])
    plan.extend(ready_queries)
    update_benefit_of_plan(ready_queries, sign=+1)
    # Add migrations one at a time (with backtracking)
    ready_migrations = [i for i in ready if G.nodes[i]["kind"] == "Migration"]
    if not ready_migrations:
        plan.extend(plan_tail)
        if benefit > best:
            best, best_plan = benefit, plan.copy()
        if benefit < worse:
            worse, worse_plan = benefit, plan.copy()
        _ = [plan.pop() for _ in range(len(plan_tail))]
        #print("Plan found:", plan, benefit)
    else:
        for current in ready_migrations:
            plan.append(current)
            # Increase the benefit of the current migration
            update_benefit_of_plan([current], sign=+1)
            # Add new nodes that became ready
            next_ready = [n for n in ready_migrations if n != current]
            for j in G.successors(current):
                if j not in plan and all([n in plan for n in G.predecessors(j)]):
                    next_ready.append(j)
            # Recursive call
            exhaustive_search(plan, next_ready, plan_tail.copy())
            # Remove the benefit of the current migration
            update_benefit_of_plan([current], sign=-1)
            # Remove the migration node from the plan
            plan.pop()
    # Remove the query nodes from the plan
    update_benefit_of_plan(ready_queries, sign=-1)
    _ = [plan.pop() for _ in range(len(ready_queries))]


def greedy_search(plan, ready, plan_tail):
    global steps
    global benefit

    steps += 1

    # Add all queries to the plan at once (no need for backtracking)
    ready_queries = [i for i in ready if G.nodes[i]["kind"] == "Query" and G.nodes[i]["benefit"] > 0]
    plan_tail.extend([i for i in ready if G.nodes[i]["kind"] == "Query" and G.nodes[i]["benefit"] <= 0])
    plan.extend(ready_queries)
    update_benefit_of_plan(ready_queries, sign=+1)
    # Take one more migration
    ready_migrations = [i for i in ready if G.nodes[i]["kind"] == "Migration"]
    if not ready_migrations:
        plan.extend(plan_tail)
        print(f"Worse plan: {plan} -> {benefit:.2f}")
    else:
        add_cumulative_duration_to_nodes(plan.copy())
        heuristics = []
        pending_benefit = sum([G.nodes[n]["benefit"] for n in G.nodes if n not in plan and G.nodes[n]["kind"] == "Query" and G.nodes[n]["benefit"] > 0])
        for node in ready_migrations:
            pending_duration = sum([G.nodes[n]["duration"] for n in G.nodes if n != node and n not in plan and G.nodes[n]["kind"] == "Migration"])
            h = 0
            related_benefit = 0
            for q in G.nodes[node]["impacted_queries"]:
                if G.nodes[q]["benefit"] > 0:
                    related_benefit += G.nodes[q]["benefit"]
                    h += pending_duration * G.nodes[q]["benefit"] * (G.nodes[node]["duration"] / G.nodes[q]["cumulative_duration"])
            h -= (pending_benefit - related_benefit) * G.nodes[node]["duration"]
            heuristics.append(h)
        current = ready_migrations[heuristics.index(max(heuristics))]
        plan.append(current)
        # Increase the benefit of the current migration
        update_benefit_of_plan([current], sign=+1)
        # Add new nodes that became ready
        next_ready = [n for n in ready_migrations if n != current]
        for j in G.successors(current):
            if j not in plan and all([n in plan for n in G.predecessors(j)]):
                next_ready.append(j)
        # Recursive call
        greedy_search(plan, next_ready, plan_tail)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Error: Input filename required as a parameter")
        exit(1)

    load_graph(Path("inputs").joinpath(sys.argv[1]))

    steps = 0
    start = time.time()
    exhaustive_search([0], get_ready_nodes(G.nodes, [0]), [])
    end = time.time()
    print(f"Best plan: {best_plan} -> {best:.2f}")
    print(f"Worse plan: {worse_plan} -> {worse:.2f}")
    print(f"{steps} search steps executed in {(end - start):.2f} seconds")

    steps = 0
    start = time.time()
    greedy_search([0], get_ready_nodes(G.nodes, [0]), [])
    end = time.time()
    print(f"{steps} search steps executed in {(end - start):.2f} seconds")
