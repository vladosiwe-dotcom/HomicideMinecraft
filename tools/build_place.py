"""Builds a Roblox place file (.rbxlx) and a Studio command-bar installer from src/."""
import os, sys, itertools
from xml.sax.saxutils import escape
import xml.etree.ElementTree as ET

root = sys.argv[1]
out_dir = os.path.join(root, "build")
os.makedirs(out_dir, exist_ok=True)

def src(path):
    with open(os.path.join(root, path), encoding="utf-8") as f:
        text = f.read()
    assert "]]>" not in text and "]==]" not in text, path
    return text

# (service class, [ (folder name or None, class, name, path) ])
layout = [
    ("ReplicatedStorage", [("Shared", "ModuleScript", "Config", "src/shared/Config.luau"),
                           ("Shared", "ModuleScript", "BodyMap", "src/shared/BodyMap.luau")]),
    ("ServerScriptService", [("Server", "Script", "Main", "src/server/Main.server.luau"),
                             ("Server", "ModuleScript", "Organism", "src/server/Organism.luau"),
                             ("Server", "ModuleScript", "Ragdoll", "src/server/Ragdoll.luau"),
                             ("Server", "ModuleScript", "Weapons", "src/server/Weapons.luau")]),
    ("StarterPlayer/StarterPlayerScripts", [(None, "LocalScript", "Main", "src/client/Main.client.luau")]),
    ("StarterPlayer/StarterCharacterScripts", [(None, "Script", "Health", "src/character/Health.server.luau")]),
]

ref = itertools.count(1)
def item(cls, name, children="", source=None):
    props = f'<string name="Name">{escape(name)}</string>'
    if source is not None:
        props += f'<ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>'
    return f'<Item class="{cls}" referent="RBX{next(ref)}"><Properties>{props}</Properties>{children}</Item>\n'

def scripts_xml(entries):
    folders, loose = {}, ""
    for folder, cls, name, path in entries:
        x = item(cls, name, source=src(path))
        if folder:
            folders[folder] = folders.get(folder, "") + x
        else:
            loose += x
    return "".join(item("Folder", f, c) for f, c in folders.items()) + loose

by_service = dict(layout)
body = item("ReplicatedStorage", "ReplicatedStorage", scripts_xml(by_service["ReplicatedStorage"]))
body += item("ServerScriptService", "ServerScriptService", scripts_xml(by_service["ServerScriptService"]))
body += item("StarterPlayer", "StarterPlayer",
             item("StarterPlayerScripts", "StarterPlayerScripts", scripts_xml(by_service["StarterPlayer/StarterPlayerScripts"]))
             + item("StarterCharacterScripts", "StarterCharacterScripts", scripts_xml(by_service["StarterPlayer/StarterCharacterScripts"])))
place = '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" version="4">\n' + body + "</roblox>\n"
ET.fromstring(place)  # must be valid XML
with open(os.path.join(out_dir, "ZCitySandbox.rbxlx"), "w", encoding="utf-8") as f:
    f.write(place)

# Command-bar installer: creates the same scripts in an open place.
lua = ['-- Paste into Roblox Studio: View > Command Bar, then press Enter.',
       'local function folder(parent, name) local f = parent:FindFirstChild(name) or Instance.new("Folder") f.Name = name f.Parent = parent return f end',
       'local function put(parent, class, name, source) local old = parent:FindFirstChild(name) if old then old:Destroy() end local s = Instance.new(class) s.Name = name s.Source = source s.Parent = parent end',
       'local SP = game:GetService("StarterPlayer")']
targets = {"ReplicatedStorage": 'game:GetService("ReplicatedStorage")',
           "ServerScriptService": 'game:GetService("ServerScriptService")',
           "StarterPlayer/StarterPlayerScripts": 'SP:FindFirstChildOfClass("StarterPlayerScripts")',
           "StarterPlayer/StarterCharacterScripts": 'SP:FindFirstChildOfClass("StarterCharacterScripts")'}
for service, entries in layout:
    for folder, cls, name, path in entries:
        parent = targets[service] if not folder else f'folder({targets[service]}, "{folder}")'
        lua.append(f'put({parent}, "{cls}", "{name}", [==[{src(path)}]==])')
lua.append('print("Z-City sandbox installed. Press Play.")')
with open(os.path.join(out_dir, "install_command_bar.lua"), "w", encoding="utf-8") as f:
    f.write("\n".join(lua) + "\n")
print("ok", len(place), "bytes")
