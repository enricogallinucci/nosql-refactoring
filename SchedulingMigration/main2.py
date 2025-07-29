import time
import json
import sys
from pathlib import Path
import networkx as nx
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import copy

G = nx.DiGraph()
benefit = 0
enabled = 0
best = 0
worst = 999999999
best_plan = [0]
worst_plan = [0]
query_frequency_in_workload = 0


def add_benefit_to_nodes():
    for current in G.nodes:
        node = G.nodes[current]
        if node["kind"] == "Query":
            node["benefit"] = node["weight"] * (node["time_before"] - node["time_after"])

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
    # for i in G.nodes:
    #     print(G.nodes[i])

def exhaustive_search(plan, mq):
    global steps
    steps += 1

    # Move the migration query mq from todo to done; migration time is extended with the duration of mq
    plan["migration_query_done"].append(mq)
    plan["migration_query_todo"].remove(mq)
    plan["duration"] += G.nodes[mq]["duration"]

    # If all predecessors of a workload query are done, it can be moved to done; the benefit is extended with the benefit of moved wqs, if any
    # If no workload queries are enabled, the plan is not added to the list of considered plans
    wqs_to_remove, addPlan = [], False
    for wq in plan["workload_query_todo"]:
        if all(mq in plan["migration_query_done"] for mq in G.predecessors(wq)):
            wqs_to_remove.append(wq)
            plan["workload_query_done"].append(wq)
            plan["benefit"] += G.nodes[wq]["benefit"]
            addPlan = True
    # Removing later to avoid modifying the list while iterating over it
    for wq_to_remove in wqs_to_remove:
        plan["workload_query_todo"].remove(wq_to_remove)
    
    if addPlan:
        global plans
        plan["time_to_compensate_migration"] = plan["duration"]*query_frequency_in_workload*1000/plan["benefit"] if plan["benefit"] > 0 else worst
        plans.append(plan)

    # Create new plans by adding further migration queries from the todo list
    for mq in plan["migration_query_todo"]:
        exhaustive_search(copy.deepcopy(plan), mq)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Error: Input filename required as a parameter")
        exit(1)
    load_graph(Path("SchedulingMigration/inputs").joinpath(sys.argv[1]))

    steps = 0
    start = time.time()

    plans = []
    # Initial plan that doesn't migrate anything
    plan = {
        "migration_query_todo": [i for i in G.nodes if G.nodes[i]["kind"] == "Migration"], "migration_query_done": [], 
        "workload_query_todo": [i for i in G.nodes if G.nodes[i]["kind"] == "Query"], "workload_query_done": [], 
        "duration": 0, "benefit": 0, "time_to_compensate_migration": worst
    }
    # plans.append(plan)
    # Create plans by adding migration queries from the todo list
    for mq in plan["migration_query_todo"]:
        exhaustive_search(copy.deepcopy(plan), mq)

    end = time.time()

    best_plan = min(plans, key=lambda x: x["time_to_compensate_migration"])
    worst_plan = max(plans, key=lambda x: x["time_to_compensate_migration"])
    print(f"Best plan: {best_plan}")
    print(f"Worst plan: {worst_plan}")
    print(f"{steps} search steps executed in {(end - start):.2f} seconds")
