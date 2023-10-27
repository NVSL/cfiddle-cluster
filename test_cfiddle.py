from cfiddle import *
import cfiddle
from  delegate_function import TestClass
import functools
import pytest
import yaml
from cfiddle.ext.delegate_function  import execution_method

cfiddle.enable_debug()

def test_test():
    pass

def test_smoke():
    b = build(code(r"""
#include <iostream>

extern "C"
void hello() {
    std::cout << "hello\n";
}
"""))
    r = run(b, "hello")

def extract_id(chain):
    d = yaml.load(chain, Loader=yaml.Loader)
    if 'sequence' in d:
        type_names = [x['type'] for x in d['sequence']]
        return  "_to_".join(type_names)
    else:
        return chain

trivial_config = """
version: 0.1
sequence:
  - type: TrivialDelegate
"""

slurm_config = """
version: 0.1
sequence:
  - type: SlurmDelegate
#    debug_pre_hook: SHELL
    temporary_file_root: /home/tmp
    delegate_executable_path: /usr/local/bin/delegate-function-run
"""
    
slurm_to_docker_config = """
version: 0.1
sequence:
  - type: SlurmDelegate
#    debug_pre_hook: SHELL
    temporary_file_root: /home/tmp
    delegate_executable_path: /usr/local/bin/delegate-function-run
  - type: DockerDelegate
    docker_image: cfiddle-sandbox:latest
#    debug_pre_hook: SHELL
    temporary_file_root: /cfiddle_scratch
    delegate_executable_path: /usr/local/bin/delegate-function-run
    docker_cmd_line_args: ['--entrypoint', '/usr/bin/env', '--mount', 'type=volume,dst=/cfiddle_scratch,source=slurm-stack_cfiddle_scratch']
"""
    
slurm_to_sudo_to_docker_config = """
version: 0.1
sequence:
  - type: SlurmDelegate
    temporary_file_root: /home/tmp
#    debug_pre_hook: SHELL
    delegate_executable_path: /usr/local/bin/delegate-function-run
  - type: SudoDelegate
#    debug_pre_hook: SHELL
    user: cfiddle
    delegate_executable_path: /usr/local/bin/delegate-function-run
  - type: DockerDelegate
#    debug_pre_hook: SHELL
    docker_image: cfiddle-sandbox:latest
    temporary_file_root: /cfiddle_scratch
    delegate_executable_path: /usr/local/bin/delegate-function-run
    docker_cmd_line_args: ['--entrypoint', '/usr/bin/env', '--mount', 'type=volume,dst=/cfiddle_scratch,source=slurm-stack_cfiddle_scratch']
"""


#@pytest.fixture(scope="module",
 #               params=chains_to_test,
#                ids=extract_ids(chains_to_test))
#def SomeYAML(request):
#    return request.param


@pytest.fixture
def the_code():
    return build(code(r"""
#include <iostream>
extern "C"
void hello() {
    std::cout << "hello\n";
}
"""))


@pytest.mark.parametrize("target_user,the_yaml",
                         [
                             ("root", trivial_config),
                             ("root", slurm_config),
                             ("root", slurm_to_docker_config),
                             ("root", slurm_to_sudo_to_docker_config),
                             ("jovyan", trivial_config),
                             ("jovyan", slurm_config),
                             ("jovyan", slurm_to_sudo_to_docker_config),
                         ],
                         ids = extract_id)
def test_delegate(the_code, the_yaml, target_user):
    import getpass
    actual_user = getpass.getuser()
    if actual_user != target_user:
        pytest.skip("This test is for {target_user} not {actual_user}")
        return
    
    with cfiddle_config(RunnerExecutionMethod_type=execution_method(the_yaml)):
        r = run(the_code, "hello")
