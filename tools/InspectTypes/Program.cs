using WolvenKit.RED4.Types;using WolvenKit.RED4.TweakDB;
static ulong Append(ulong id,string text){uint crc=~(uint)id;foreach(byte b in System.Text.Encoding.UTF8.GetBytes(text)){crc^=b;for(int i=0;i<8;i++)crc=(crc>>1)^((crc&1)!=0?0xEDB88320u:0);}return ((id>>32)+(ulong)text.Length)<<32|~crc;}
if(Append(TweakDBID.CalculateHash("hello"),".world")!=TweakDBID.CalculateHash("hello.world"))throw new Exception("CRC check");
using var s=File.OpenRead(@"E:\Games\Cyberpunk 2077\r6\cache\tweakdb.bin");using var reader=new TweakDBReader(s);Console.WriteLine(reader.ReadFile(out var db));
foreach(var field in new[]{"primaryEquipment","secondaryEquipment"}){
 var group=(TweakDBID)db.GetFlatValue("Character.dtn_animals_bouncer2_melee2_fists_mb."+field);Console.WriteLine(field);
 var entries=(CArray<TweakDBID>)db.Flats.GetValue(Append(group,".equipmentItems"));
 foreach(var entry in entries){var item=(TweakDBID)db.Flats.GetValue(Append(entry,".item"));var type=(TweakDBID)db.Flats.GetValue(Append(item,".itemType"));Console.WriteLine($"entry={(ulong)entry}; item={(ulong)item}; typeName={db.Flats.GetValue(Append(type,".name"))}; type={(ulong)type}");}
}
