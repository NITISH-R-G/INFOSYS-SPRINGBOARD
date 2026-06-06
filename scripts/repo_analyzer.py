import os
import json
import ast
import re
from pathlib import Path

def analyze_repository(repo_path='.'):
    """
    Analyzes the repository to detect frameworks, libraries, services, APIs,
    databases, deployment targets, infrastructure, and builds a knowledge graph.
    """
    repo_path = Path(repo_path)

    knowledge_graph = {
        "structure": {},
        "frameworks": [],
        "languages": set(),
        "dependencies": {},
        "services": [],
        "databases": [],
        "apis": [],
        "infrastructure": [],
        "module_relationships": []
    }

    ignore_dirs = {'.git', 'node_modules', 'venv', '__pycache__', '.pytest_cache', 'build', 'dist', 'scripts', '.github'}

    for root, dirs, files in os.walk(repo_path):
        dirs[:] = [d for d in dirs if d not in ignore_dirs]

        rel_path = os.path.relpath(root, repo_path)
        if rel_path == '.':
            rel_path = ''

        current_node = knowledge_graph["structure"]
        if rel_path:
            for part in Path(rel_path).parts:
                if part not in current_node:
                    current_node[part] = {}
                current_node = current_node[part]

        for file in files:
            file_path = Path(root) / file
            rel_file_path = str(file_path.relative_to(repo_path))

            # Record structure
            current_node[file] = "file"

            # Detect languages
            ext = file_path.suffix.lower()
            if ext == '.py':
                knowledge_graph["languages"].add("Python")
                analyze_python_file(file_path, rel_file_path, knowledge_graph)
            elif ext in ['.js', '.jsx']:
                knowledge_graph["languages"].add("JavaScript")
            elif ext in ['.ts', '.tsx']:
                knowledge_graph["languages"].add("TypeScript")
            elif ext == '.java':
                knowledge_graph["languages"].add("Java")
            elif ext == '.go':
                knowledge_graph["languages"].add("Go")
            elif ext in ['.yaml', '.yml']:
                analyze_yaml_file(file_path, knowledge_graph)
            elif ext == '.json' and file == 'package.json':
                analyze_package_json(file_path, knowledge_graph)
            elif file == 'requirements.txt':
                analyze_requirements_txt(file_path, knowledge_graph)
            elif file == 'Dockerfile':
                knowledge_graph["infrastructure"].append(rel_file_path)

    # Convert sets to lists for JSON serialization
    knowledge_graph["languages"] = list(knowledge_graph["languages"])

    # Save the knowledge graph
    output_path = repo_path / "repo_knowledge_graph.json"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(knowledge_graph, f, indent=2)

    print(f"Repository analysis complete. Knowledge graph saved to {output_path}")

def analyze_python_file(file_path, rel_file_path, knowledge_graph):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        tree = ast.parse(content)

        imports = []
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    imports.append(alias.name)
            elif isinstance(node, ast.ImportFrom):
                if node.module:
                    imports.append(node.module)

        if imports:
            knowledge_graph["dependencies"][rel_file_path] = imports
            for imp in imports:
                knowledge_graph["module_relationships"].append({
                    "source": rel_file_path,
                    "target": imp,
                    "type": "import"
                })

                # Detect frameworks from imports
                if imp.startswith('flask') or imp.startswith('django') or imp.startswith('fastapi'):
                    if imp.split('.')[0] not in knowledge_graph["frameworks"]:
                        knowledge_graph["frameworks"].append(imp.split('.')[0])
                elif imp.startswith('sqlalchemy') or imp.startswith('pymongo') or imp.startswith('psycopg2'):
                    db = imp.split('.')[0]
                    if db not in knowledge_graph["databases"]:
                        knowledge_graph["databases"].append(db)

    except Exception as e:
        pass # Ignore parsing errors

def analyze_yaml_file(file_path, knowledge_graph):
    # Basic scanning for common CI/CD or infra keywords
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            if 'github.com' in content and 'actions' in content:
                knowledge_graph["infrastructure"].append(str(file_path))
            if 'kubernetes' in content or 'kind:' in content:
                knowledge_graph["infrastructure"].append(str(file_path))
    except Exception as e:
        pass

def analyze_package_json(file_path, knowledge_graph):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        deps = data.get('dependencies', {})
        dev_deps = data.get('devDependencies', {})

        all_deps = {**deps, **dev_deps}

        rel_file_path = str(file_path.relative_to(Path('.')))
        knowledge_graph["dependencies"][rel_file_path] = list(all_deps.keys())

        # Detect common JS frameworks
        js_frameworks = ['react', 'vue', 'angular', 'next', 'express', 'nestjs']
        for fw in js_frameworks:
            if fw in all_deps and fw not in knowledge_graph["frameworks"]:
                knowledge_graph["frameworks"].append(fw)

    except Exception as e:
        pass

def analyze_requirements_txt(file_path, knowledge_graph):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        deps = []
        for line in lines:
            line = line.strip()
            if line and not line.startswith('#'):
                # Extract package name (simple regex to drop versions)
                pkg = re.split(r'[=<>~]', line)[0].strip()
                if pkg:
                    deps.append(pkg)

        rel_file_path = str(file_path.relative_to(Path('.')))
        knowledge_graph["dependencies"][rel_file_path] = deps

    except Exception as e:
        pass

if __name__ == "__main__":
    analyze_repository()
