# playbooks

Esta carpeta contiene los playbooks y roles de Ansible para aprovisionar y configurar los servidores y servicios del proyecto.

## ¿Qué vas a encontrar?
- `deploy.yml`: Playbook principal para el despliegue automatizado.
- `roles/`: Roles reutilizables (web-server, lvm, common, etc).

## Ejemplo de uso
```bash
ansible-playbook playbooks/deploy.yml
```

> Tip: Podés personalizar los roles y variables según el entorno o la necesidad del grupo. 