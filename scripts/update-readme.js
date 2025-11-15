const fs = require('fs');
const path = require('path');

const defaultsDir = path.join(__dirname, '../ansible/roles');
const readmeFile = path.join(__dirname, '../ansible/README.md');

function getVersion(filePath, key) {
  const content = fs.readFileSync(filePath, 'utf8');
  const regex = new RegExp(`${key}:\\s*'\\{\\{.*?or\\s*"([^"]+)"\\s*\\}\\}'`);
  const match = content.match(regex);
  return match ? match[1] : null;
}

const deps = [
  { key: 'cni_version', file: 'install-cni/defaults/main.yml' },
  { key: 'containerd_version', file: 'install-containerd/defaults/main.yml' },
  { key: 'crictl_version', file: 'install-crictl/defaults/main.yml' },
  { key: 'runc_version', file: 'install-runc/defaults/main.yml' },
  { key: 'k8s_release_version', file: 'install-kubeadm-kubelet/defaults/main.yml' },
  { key: 'k8s_service_release_version', file: 'install-kubeadm-kubelet/defaults/main.yml' },
  { key: 'kubectl_version', file: 'install-kubectl/defaults/main.yml' },
];

let readme = fs.readFileSync(readmeFile, 'utf8');

deps.forEach(dep => {
  const fullPath = path.join(defaultsDir, dep.file);
  const version = getVersion(fullPath, dep.key);
  if (version) {
    const regex = new RegExp(
      `(\\\`?${dep.key}\\\`?\\s*\\|\\s*)(\\\`[^\\\`]+\\\`)`,
      'g'
    );
    readme = readme.replace(regex, `$1\`${version}\``);
  }
});

fs.writeFileSync(readmeFile, readme);
console.log('README.md updated with latest versions.');