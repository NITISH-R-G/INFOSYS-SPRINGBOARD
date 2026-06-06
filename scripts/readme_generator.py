import json
import os
from pathlib import Path

def generate_readme(kg_path='repo_knowledge_graph.json', output_path='README.md'):
    """Generates an up-to-date README based on the knowledge graph."""

    try:
        with open(kg_path, 'r', encoding='utf-8') as f:
            kg = json.load(f)
    except FileNotFoundError:
        print(f"Error: {kg_path} not found.")
        return

    readme_content = []

    # Header
    repo_name = os.path.basename(os.path.abspath('.'))
    readme_content.append(f"# {repo_name}")
    readme_content.append("")
    readme_content.append("![Auto-maintained](https://img.shields.io/badge/Maintained%20by-Automation-blue)")
    readme_content.append("")

    # Overview
    readme_content.append("## Overview")
    readme_content.append("This repository is fully autonomous and self-documenting. Documentation, architecture diagrams, and knowledge graphs are automatically generated and updated via CI/CD pipelines whenever code changes occur.")
    readme_content.append("")

    # Technology Stack
    readme_content.append("## Technology Stack")

    if kg.get("languages"):
        readme_content.append("### Languages")
        for lang in kg["languages"]:
            readme_content.append(f"- {lang}")

    if kg.get("frameworks"):
        readme_content.append("### Frameworks & Libraries")
        for fw in kg["frameworks"]:
            readme_content.append(f"- {fw}")

    if kg.get("databases"):
        readme_content.append("### Databases")
        for db in kg["databases"]:
            readme_content.append(f"- {db}")

    readme_content.append("")

    # Architecture
    readme_content.append("## Architecture")
    readme_content.append("### Architecture Diagram")

    try:
        with open('architecture_diagram.md', 'r', encoding='utf-8') as f:
            readme_content.append(f.read())
    except FileNotFoundError:
        readme_content.append("*(Architecture diagram not available)*")

    readme_content.append("")
    readme_content.append("### Module Relationships")
    try:
        with open('module_relationships.md', 'r', encoding='utf-8') as f:
            readme_content.append(f.read())
    except FileNotFoundError:
        readme_content.append("*(Module relationship diagram not available)*")

    readme_content.append("")

    # Repository Structure
    readme_content.append("## Repository Structure")
    readme_content.append("```text")

    def render_tree(node, prefix="", is_last=True):
        lines = []
        keys = list(node.keys())
        for i, key in enumerate(keys):
            is_last_item = (i == len(keys) - 1)
            connector = "└── " if is_last_item else "├── "

            if isinstance(node[key], dict):
                lines.append(f"{prefix}{connector}{key}/")
                extension = "    " if is_last_item else "│   "
                lines.extend(render_tree(node[key], prefix + extension, is_last_item))
            else:
                lines.append(f"{prefix}{connector}{key}")
        return lines

    structure = render_tree(kg.get("structure", {}))
    # Limit structure depth if it's too long
    if len(structure) > 30:
        structure = structure[:30] + ["... (truncated for brevity)"]

    readme_content.extend(structure)
    readme_content.append("```")
    readme_content.append("")

    # Setup Instructions
    readme_content.append("## Setup & Installation")
    readme_content.append("*(Auto-generated based on detected technologies)*")
    if "Python" in kg.get("languages", []):
        readme_content.append("### Python Setup")
        readme_content.append("```bash")
        readme_content.append("python -m venv venv")
        readme_content.append("source venv/bin/activate  # On Windows use `venv\\Scripts\\activate`")
        if any(f == 'requirements.txt' for f in kg.get("structure", {})):
            readme_content.append("pip install -r requirements.txt")
        readme_content.append("```")

    if "JavaScript" in kg.get("languages", []) or "TypeScript" in kg.get("languages", []):
        readme_content.append("### Node.js Setup")
        readme_content.append("```bash")
        if any(f == 'package.json' for f in kg.get("structure", {})):
            readme_content.append("npm install")
            readme_content.append("npm start")
        readme_content.append("```")

    readme_content.append("")

    # Contributing
    readme_content.append("## Contribution Guide")
    readme_content.append("1. Fork the repository.")
    readme_content.append("2. Create a feature branch.")
    readme_content.append("3. Commit your changes. (The CI/CD pipeline will automatically update documentation and diagrams)")
    readme_content.append("4. Submit a Pull Request.")

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(readme_content))

    print(f"README.md successfully updated at {output_path}")

if __name__ == "__main__":
    generate_readme()
