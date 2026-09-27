using WolvenKit.RED4.Archive;
using WolvenKit.RED4.CR2W;
using WolvenKit.RED4.Archive.CR2W;
using WolvenKit.RED4.Archive.IO;
using WolvenKit.RED4.Types;

if(args.Length != 1) throw new ArgumentException("Specify output .ent path");
var template = new entEntityTemplate
{
    DefaultAppearance = "default",
    Entity = new CHandle<entEntity> { Chunk = new gameItemObject() },
    Components = new CArray<entIComponent>
    {
        new entPhysicalMeshComponent
        {
            Name = "deathclaw_statue",
            Mesh = new CResourceAsyncReference<CMesh>(@"local\deathclaw_badlands\deathclaw.mesh"),
            MeshAppearance = "default",
        },
        new gameTargetingComponent { Name = "targeting" },
    }
};
Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(args[0]))!);
using var output = File.Create(args[0]);
using var writer = new CR2WWriter(output);
writer.WriteFile(new CR2WFile { RootChunk = template });
Console.WriteLine($"Generated prop entity using WolvenKit's native constructors: {args[0]}");
