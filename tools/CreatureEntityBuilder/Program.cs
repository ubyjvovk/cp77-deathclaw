using WolvenKit.RED4.CR2W;
using WolvenKit.RED4.Archive.IO;
using WolvenKit.RED4.Types;

if(args.Length!=2) throw new ArgumentException("donor.ent output.ent");
using var input=File.OpenRead(args[0]);
using var reader=new CR2WReader(input);
reader.ReadFile(out var file);
var entity=(entEntityTemplate)file.RootChunk;
entity.Appearances.Clear();
entity.DefaultAppearance="default";
entity.Components.Add(new entSkinnedMeshComponent {
    Name="protectors",
    Mesh=new CResourceAsyncReference<CMesh>(@"local\deathclaw_creature\deathclaw_android.mesh"),
    MeshAppearance="default",
    AcceptDismemberment=false,
    Skinning=new CHandle<entSkinningBinding>{Chunk=new entSkinningBinding{BindName="deformations"}},
});
Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(args[1]))!);
using var output=File.Create(args[1]);
using var writer=new CR2WWriter(output);
writer.WriteFile(file);
Console.WriteLine($"Created large brawler NPC: {entity.Components.Count} components");
