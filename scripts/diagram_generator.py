import json
import os
from pathlib import Path

def generate_diagrams(knowledge_graph_path='repo_knowledge_graph.json', output_dir='.'):
    """
    Generates Mermaid diagrams based on the repository knowledge graph.
    """
    try:
        with open(knowledge_graph_path, 'r', encoding='utf-8') as f:
            kg = json.load(f)
    except FileNotFoundError:
        print(f"Error: {knowledge_graph_path} not found. Run repo_analyzer.py first.")
        return

    output_dir = Path(output_dir)
    os.makedirs(output_dir, exist_ok=True)

    # Generate Architecture/Dependency Map
    generate_architecture_diagram(kg, output_dir / 'architecture_diagram.md')

    # Generate Module Relationship Graph
    generate_module_relationship_diagram(kg, output_dir / 'module_relationships.md')

    print(f"Diagrams generated successfully in {output_dir}")

def generate_architecture_diagram(kg, output_path):
    """Generates a high-level architecture diagram."""
    mermaid = ["```mermaid", "graph TD"]
    mermaid.append("    subgraph Repository Architecture")

    # Add frameworks
    if kg.get("frameworks"):
        mermaid.append("        subgraph Frameworks")
        for i, fw in enumerate(kg["frameworks"]):
            mermaid.append(f"            F{i}[{fw}]")
        mermaid.append("        end")

    # Add databases
    if kg.get("databases"):
        mermaid.append("        subgraph Databases")
        for i, db in enumerate(kg["databases"]):
            mermaid.append(f"            D{i}[({db})]")
        mermaid.append("        end")

    # Add languages
    if kg.get("languages"):
        mermaid.append("        subgraph Languages")
        for i, lang in enumerate(kg["languages"]):
            mermaid.append(f"            L{i}({lang})")
        mermaid.append("        end")

    mermaid.append("    end")
    mermaid.append("```")

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(mermaid))

def generate_module_relationship_diagram(kg, output_path):
    """Generates a graph of internal module relationships."""
    mermaid = ["```mermaid", "graph LR"]

    relationships = kg.get("module_relationships", [])

    if not relationships:
        mermaid.append("    No internal module relationships detected.")
    else:
        # To avoid massive graphs, limit or group
        # Here we do a simplified version, extracting just the filename/module name
        nodes = {}
        node_id_counter = 0

        def get_node_id(name):
            nonlocal node_id_counter
            # simplify name
            simple_name = name.split('/')[-1] if '/' in name else name
            simple_name = simple_name.split('\\')[-1] if '\\' in simple_name else simple_name

            if simple_name not in nodes:
                nodes[simple_name] = f"N{node_id_counter}"
                node_id_counter += 1
            return nodes[simple_name], simple_name

        added_edges = set()

        node_links = {}
        for rel in relationships:
            source = rel["source"]
            target = rel["target"]

            s_id, s_name = get_node_id(source)
            t_id, t_name = get_node_id(target)

            # Store link paths for deep linking
            if source and not source.startswith('.'):
                node_links[s_id] = source

            edge = f"{s_id} --> {t_id}"
            if edge not in added_edges:
                # Add nodes definition
                mermaid.append(f"    {s_id}[{s_name}]")
                mermaid.append(f"    {t_id}[{t_name}]")
                mermaid.append(f"    {edge}")
                added_edges.add(edge)

            if len(added_edges) > 50: # Limit size to prevent rendering issues
                mermaid.append("    %% Graph truncated for readability")
                break

        for n_id, path in node_links.items():
            # Deep link to github source. In a real repo this would be derived from git remote.
            # Here we provide a relative link structure common in markdown.
            mermaid.append(f"    click {n_id} href \"./{path}\" \"View source file\"")

    mermaid.append("```")

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(mermaid))

if __name__ == "__main__":
    generate_diagrams()
