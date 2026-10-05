import os
import unreal

SRC = r"C:\Users\PC\Documents\Fortnite Projects\FallGuys_Test\sfx"
DEST = "/FallGuys_Sample/Audio"

tasks = []
for name in sorted(os.listdir(SRC)):
    if not name.lower().endswith(".wav"):
        continue
    task = unreal.AssetImportTask()
    task.filename = os.path.join(SRC, name)
    task.destination_path = DEST
    task.destination_name = os.path.splitext(name)[0]
    task.automated = True
    task.save = True
    task.replace_existing = True
    task.factory = unreal.SoundFactory()
    tasks.append(task)

unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks(tasks)
unreal.log("import_sfx: imported {} wav files into {}".format(len(tasks), DEST))
