from cfiddle import *
import cfiddle
import delegate_function
import functools
import pytest
import yaml
from cfiddle.ext.delegate_function  import execution_method

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

def extract_ids(chains):
    r = []
    for c in chains:
        d = yaml.load(c, Loader=yaml.Loader)
        type_names = [x['type'] for x in d['sequence']]
        name = "_to_".join(type_names) 
        r.append(name)
    return r

chains_to_test = [
"""
version: 0.1
sequence:
  - type: SlurmDelegate
    temporary_file_root: /home/tmp
    delegate_executable_path: /usr/local/bin/delegate-function-run
"""
    ,
"""
version: 0.1
sequence:
  - type: SlurmDelegate
    temporary_file_root: /home/tmp
    delegate_executable_path: /usr/local/bin/delegate-function-run
  - type: DockerDelegate
    docker_image: cfiddle-sandbox:latest
    temporary_file_root: /cfiddle_scratch
    delegate_executable_path: /usr/local/bin/delegate-function-run
    docker_cmd_line_args: ['--entrypoint', '/usr/bin/env', '--mount', 'type=volume,dst=/cfiddle_scratch,source=slurm-stack_cfiddle_scratch']
"""
    ,
"""
version: 0.1
sequence:
  - type: SlurmDelegate
    temporary_file_root: /home/tmp
    delegate_executable_path: /usr/local/bin/delegate-function-run
  - type: SudoDelegate
    user: cfiddle
    delegate_executable_path: /usr/local/bin/delegate-function-run
  - type: DockerDelegate
    docker_image: cfiddle-sandbox:latest
    temporary_file_root: /cfiddle_scratch
    delegate_executable_path: /usr/local/bin/delegate-function-run
    docker_cmd_line_args: ['--entrypoint', '/usr/bin/env', '--mount', 'type=volume,dst=/cfiddle_scratch,source=slurm-stack_cfiddle_scratch']
"""
]

@pytest.fixture(scope="module",
                params=chains_to_test,
                ids=extract_ids(chains_to_test))
def SomeYAML(request):
    return request.param

def test_delegate(SomeYAML):
    cfiddle.enable_debug()
    with cfiddle_config(RunnerExecutionMethod_type=execution_method(SomeYAML)):
        b = build(code(r"""
#include <iostream>

extern "C"
void hello() {
    std::cout << "hello\n";
}
"""))
        r = run(b, "hello")

