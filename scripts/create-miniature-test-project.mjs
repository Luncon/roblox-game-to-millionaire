import fs from 'node:fs';
import path from 'node:path';

const root=process.cwd();
const project=JSON.parse(fs.readFileSync(path.join(root,'miniature.project.json'),'utf8'));
function relocate(instance) {
  for(const [key,value] of Object.entries(instance)) {
    if(key==='$path') instance[key]=`../${value}`;
    else if(value && typeof value==='object') relocate(value);
  }
}
relocate(project.tree);
project.name+='Tests';
project.tree.ServerScriptService.SceneChecks={$path:'../tests/miniature/Scene.server.luau'};
project.tree.ServerStorage.TemplateFingerprint={$path:'../tests/miniature/Templates.luau'};
project.tree.ReplicatedStorage.NativeInputChecks={$path:'../tests/miniature/Input.luau'};
fs.mkdirSync(path.join(root,'.cache'),{recursive:true});
fs.mkdirSync(path.join(root,'build'),{recursive:true});
fs.writeFileSync(path.join(root,'.cache/miniature-test.project.json'),JSON.stringify(project,null,2)+'\n');
console.log('Created .cache/miniature-test.project.json; build with Rojo, record the Edit template fingerprint, then run NativeInputChecks in Client.');
