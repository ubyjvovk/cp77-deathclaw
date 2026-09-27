using WolvenKit.RED4.Archive.CR2W;
using WolvenKit.RED4.Types;
using WolvenKit.RED4.CR2W;
using WolvenKit.RED4.Archive.IO;
using static WolvenKit.RED4.Types.Enums;
static CR2WFile Read(string path){using var s=File.OpenRead(path);using var r=new CR2WReader(s);r.ReadFile(out var f);return f;}
static void Write(CR2WFile f,string path){Directory.CreateDirectory(Path.GetDirectoryName(path)!);using var s=File.Create(path);using var w=new CR2WWriter(s);w.WriteFile(f);}
var graphFile=Read(args[0]);var graph=(animAnimGraph)graphFile.RootChunk;
var root=(animAnimNode_Root)graph.RootNode.Chunk;
var outputNode=(animAnimNode_Output)root.Nodes.Single().Chunk;
var scaleNode=new animAnimNode_SetBoneTransform{Id=900001,DebugName="MotherRootScale2x",InputLink=outputNode.Node};
scaleNode.Entries.Add(new animSetBoneTransformEntry{TransformToChange=new animTransformIndex{Name="Root"},SetMethod=animSetBoneTransformEntry_SetMethod.NoSnapping,Offset=new QsTransform{Scale=new Vector4{X=2,Y=2,Z=2,W=1},Rotation=new Quaternion{R=1}}});
root.Nodes.Add(new CHandle<animAnimNode_Base>{Chunk=scaleNode});
outputNode.Node=new animPoseLink{Node=new CWeakHandle<animAnimNode_Base>{Chunk=scaleNode}};
Write(graphFile,Path.Combine(args[2],"deathclaw_mother.animgraph"));
var entityFile=Read(args[1]);var ent=(entEntityTemplate)entityFile.RootChunk;
foreach(var c in ent.Components.OfType<entAnimatedComponent>()) {
 c.UseLongRangeVisibility=true;c.ClientForcedVisibility=true;
 if(c.Name=="deformations")c.Graph=new CResourceReference<animAnimGraph>(@"local\deathclaw_creature\deathclaw_mother.animgraph");
}
Write(entityFile,Path.Combine(args[2],"deathclaw_mother.ent"));
var check=(animAnimGraph)Read(Path.Combine(args[2],"deathclaw_mother.animgraph")).RootChunk;
var checkRoot=(animAnimNode_Root)check.RootNode.Chunk;
var checkOutput=(animAnimNode_Output)checkRoot.Nodes[0].Chunk;
var checkScale=(animAnimNode_SetBoneTransform)checkOutput.Node.Node.Chunk;
if(checkScale.Entries[0].Offset.Scale.X!=2 || checkScale.InputLink.Node?.Chunk==null)throw new Exception("Scale graph readback failed");
Console.WriteLine($"Mother graph readback: root scale2; upstream {checkScale.InputLink.Node.Chunk.GetType().Name}; graph and entity written.");
