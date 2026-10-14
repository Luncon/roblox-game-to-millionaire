# Civilization melee templates

Rojo maps `npc-templates/*.rbxm` to `ServerStorage.NPCTemplates`. These are exported copies of the five models the user placed in Studio:

| Asset | Civilization | Original model |
| --- | --- | --- |
| sparta.rbxm | Sparta | Workspace.GiraffeStrange |
| britain.rbxm | Britain | Workspace.little british dude |
| japan.rbxm | Japan | Workspace.Ninja |
| seneca.rbxm | Seneca | Workspace.Models.Native (inner character) |
| maurya.rbxm | Maurya | Workspace.Indian Guy |

The original Workspace models are preserved. Melee spawns clone the templates, retain clothing and headwear, remove embedded logic, and repair/unanchor the rig before it enters Workspace. Weapon and armor upgrades add generated gear without replacing the original clothing. Ranged troops and civilizations without a template keep their generated rigs.

To replace a template, export its R6 character model as the corresponding `.rbxm` file, preserving a Humanoid, HumanoidRootPart, Torso, Head, four limbs and their six body joints. Restart Play after Rojo sync. Runtime edits to the stored template are not automatically written back to the asset file.
