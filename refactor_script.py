import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    original = content
    
    # Replace class names
    content = content.replace('TeamCubit', 'TeamBloc')
    content = content.replace('team_cubit.dart', 'team_bloc.dart')
    content = content.replace('ServantDataCubit', 'ServantDataBloc')
    content = content.replace('servant_data_cubit.dart', 'servant_data_bloc.dart')

    # TeamBloc methods -> events
    content = re.sub(r'(\w+)\.loadAllTeams\(\)', r'\1.add(const TeamLoadAllRequested())', content)
    content = re.sub(r'(\w+)\.loadTeamsByGroup\(([^)]+)\)', r'\1.add(TeamLoadRequested(\2))', content)
    content = re.sub(r'(\w+)\.loadTeamsByIds\(([^)]+)\)', r'\1.add(TeamLoadByIdsRequested(\2))', content)
    content = re.sub(r'(\w+)\.selectTeam\(([^)]+)\)', r'\1.add(TeamSelected(\2))', content)
    content = re.sub(r'(\w+)\.createTeam\(([^)]+)\)', r'\1.add(TeamCreateRequested(\2))', content)
    content = re.sub(r'(\w+)\.updateTeam\(([^)]+)\)', r'\1.add(TeamUpdateRequested(\2))', content)
    content = re.sub(r'(\w+)\.deleteTeam\(([^)]+)\)', r'\1.add(TeamDeleteRequested(\2))', content)
    content = re.sub(r'(\w+)\.restoreTeam\(([^)]+)\)', r'\1.add(TeamRestoreRequested(\2))', content)
    
    content = re.sub(r'context\.read<TeamBloc>\(\)\.assignServant\((.*?)\)', r'context.read<TeamBloc>().add(ServantAssignedToTeam(\1))', content, flags=re.DOTALL)
    content = re.sub(r'context\.read<TeamBloc>\(\)\.unassignServant\((.*?)\)', r'context.read<TeamBloc>().add(ServantUnassignedFromTeam(\1))', content, flags=re.DOTALL)

    content = re.sub(r'context\.read<ServantDataBloc>\(\)\.loadServants\((.*?)\)', r'context.read<ServantDataBloc>().add(ServantsLoadRequested(\1))', content, flags=re.DOTALL)
    content = re.sub(r'context\.read<ServantDataBloc>\(\)\.searchServants\((.*?)\)', r'context.read<ServantDataBloc>().add(ServantsSearchRequested(\1))', content, flags=re.DOTALL)
    content = re.sub(r'context\.read<ServantDataBloc>\(\)\.createServant\((.*?)\)', r'context.read<ServantDataBloc>().add(ServantCreateRequested(\1))', content, flags=re.DOTALL)
    content = re.sub(r'context\.read<ServantDataBloc>\(\)\.updateServant\((.*?)\)', r'context.read<ServantDataBloc>().add(ServantUpdateRequested(\1))', content, flags=re.DOTALL)
    content = re.sub(r'context\.read<ServantDataBloc>\(\)\.deleteServant\((.*?)\)', r'context.read<ServantDataBloc>().add(ServantDeleted(\1))', content, flags=re.DOTALL)
    content = re.sub(r'context\.read<ServantDataBloc>\(\)\.restoreServant\((.*?)\)', r'context.read<ServantDataBloc>().add(ServantRestored(\1))', content, flags=re.DOTALL)
    content = re.sub(r'context\.read<ServantDataBloc>\(\)\.refreshServants\((.*?)\)', r'context.read<ServantDataBloc>().add(ServantsRefreshRequested(\1))', content, flags=re.DOTALL)
    content = re.sub(r'context\.read<ServantDataBloc>\(\)\.loadMoreServants\((.*?)\)', r'context.read<ServantDataBloc>().add(ServantsLoadMoreRequested(\1))', content, flags=re.DOTALL)

    if original != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for d in ['lib', 'test']:
    for root, _, files in os.walk(d):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))
