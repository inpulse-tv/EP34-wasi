import os
import sys
import dagger
import json


def terraform(client: dagger.Client, base: dagger.Container, folder_path: str, env_vars: list[str]):
    tf_files = (client
                .host()
                .directory(folder_path, include=["*.tf"])
                )

    tf_state = (client
                .host()
                .directory(folder_path + "/state")
                )

    for env_var in env_vars:
        base = base.with_env_variable(
            env_var, client.host().env_variable(env_var).value())

    return (base
            .with_file("./terraform.tf", tf_files.file("terraform.tf"))
            # .with_exec(["terraform", "providers", "mirror", "/usr/share/terraform/providers"])
            .with_exec(["terraform", "init"])
            .with_directory("./state", tf_files)
            .with_mounted_directory("./state", tf_state)
            .with_exec(["terraform", "apply", "-auto-approve"])
            .with_exec(["terraform", "output", "-json"])

            )


with dagger.Connection(dagger.Config(log_output=sys.stdout, execute_timeout=1800)) as client:
    tf_ssh_var = client.host().env_variable("TF_VAR_ssh")
    scw_secret_key = client.host().env_variable("SCW_SECRET_KEY").secret()
    private_key = client.host().directory(".").file("id_ed25519").secret()

    terraform_cli_config = client.host().directory(
        ".", include=".terraformrc").file(".terraformrc")

    base_tf = (client
               .container()
               .from_("hashicorp/terraform:1.4.0-alpha20221207")
               .with_workdir("/tf")
               .with_file("/config.tfrc", terraform_cli_config)
               .with_env_variable("TF_CLI_CONFIG_FILE ", "/config.tfrc")
               .with_entrypoint([]))

    # tf_infra = terraform(client, base_tf, "./deploy/infra",
    #                      ["TF_VAR_ssh"])
    # tf_output = json.load(tf_infra.stdout())
    # kubeconfig = tf_infra.file("kubeconfig")
    kubeconfig = client.host().directory("./deploy/infra").file("kubeconfig")

    # To be replace by dagger output
    tf_output = {}
    with open("./deploy/infra/output.json", "r") as f:
        tf_output = json.loads(f.read())

    all_inventory = ",".join(tf_output["aws_instances"]["value"] +
                             tf_output["scaleway_instances"]["value"]) + ","
    external_inventory = ",".join(tf_output["aws_instances"]["value"]) + ","

    aws_pool_id = tf_output["aws_pool_id"]["value"]

    ansible_playbook = (client
                        .host()
                        .directory("./deploy/ansible")
                        )

    ansible = (client
               .container()
               .from_("python:3.11.1-bullseye")
               .with_exec(["pip", "install", "ansible"])
               .with_mounted_secret("private_key", private_key)
               )

    _ = (ansible
         .with_file("playbook.yaml", ansible_playbook.file("multi.yaml"))
         .with_exec(["ansible-playbook", "-i", external_inventory,
                     "-e", "pool_id=" + aws_pool_id,
                     "-e", "scw_secret_key=" + scw_secret_key.plaintext(),
                           "-u", "ubuntu",
                           "--private-key", "./private_key",
                           "--ssh-extra-args=-oStrictHostKeyChecking=no",
                           "playbook.yaml"])
         .exit_code()
         )

    _ = (ansible
         .with_file("playbook.yaml", ansible_playbook.file("containerd-shim.yaml"))
         .with_exec(["ansible-playbook", "-i", all_inventory,
                     "-u", "ubuntu",
                           "--private-key", "./private_key",
                           "--ssh-extra-args=-oStrictHostKeyChecking=no",
                           "playbook.yaml"])
         .exit_code()
         )

    base_tf = base_tf.with_file(".", kubeconfig)
    tf_kube = terraform(client, base_tf, "./deploy/kube",
                        ["TF_VAR_ssh"]).exit_code()
