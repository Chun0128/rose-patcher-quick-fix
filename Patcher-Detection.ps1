# Reads original signed files; does not alter DLL code or support dates.
if(-not ('RosePatcherPeReaderV12' -as [type])) {
 Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;
public static class RosePatcherPeReaderV12 {
 public static uint ReadEol(string path) {
  byte[] b=File.ReadAllBytes(path);
  if(b.Length<64 || b[0]!=77 || b[1]!=90) throw new InvalidDataException("Invalid PE file");
  int pe=BitConverter.ToInt32(b,60);
  if(pe<0 || pe>b.Length-24 || BitConverter.ToUInt32(b,pe)!=0x4550 || BitConverter.ToUInt16(b,pe+4)!=0x8664) throw new InvalidDataException("Invalid x64 PE header");
  int count=BitConverter.ToUInt16(b,pe+6), table=pe+24+BitConverter.ToUInt16(b,pe+20);
  if(table<0 || table>b.Length || count>(b.Length-table)/40) throw new InvalidDataException("Invalid PE sections");
  byte[] message=Encoding.ASCII.GetBytes("end of life reached, please update: ");
  int msg=-1;
  for(int k=0;k<=b.Length-message.Length;k++) {
   if(b[k]!=message[0]) continue;
   int n=1;while(n<message.Length && b[k+n]==message[n])n++;
   if(n==message.Length){msg=k;break;}
  }
  if(msg<0) throw new InvalidDataException("Cannot locate patcher support limit");
  long msgRva=-1;int codeRva=0,codeRaw=0,codeSize=0;
  for(int k=0;k<count;k++) {
   int e=table+k*40;
   int rva=BitConverter.ToInt32(b,e+12), size=BitConverter.ToInt32(b,e+16), raw=BitConverter.ToInt32(b,e+20);
   if(raw<0 || size<0 || raw>b.Length || size>b.Length-raw) throw new InvalidDataException("Invalid PE section bounds");
   if(msg>=raw && msg-raw<size)msgRva=(long)rva+msg-raw;
   if(Encoding.ASCII.GetString(b,e,8).TrimEnd('\0')==".text"){codeRva=rva;codeRaw=raw;codeSize=size;}
  }
  if(msgRva<0 || codeSize==0)throw new InvalidDataException("Missing PE code section");
  for(int i=0;i<codeSize-7;i++) {
   int at=codeRaw+i;
   if((b[at]!=0x48 && b[at]!=0x4c)||b[at+1]!=0x8d||(b[at+2]&0xc7)!=5)continue;
   long delta=msgRva-((long)codeRva+i+7+BitConverter.ToInt32(b,at+3));
   if(delta<0 || delta>16)continue;
   for(int j=i-11;j>=Math.Max(0,i-256);j--) {
    int p=codeRaw+j;
    if(b[p]==0x3d && b[p+5]==0x0f && b[p+6]==0x86) {
     uint value=BitConverter.ToUInt32(b,p+1);
     if(value<1577836800 || value>4102444800)throw new InvalidDataException("Unrecognized support timestamp");
     return value;
    }
   }
  }
  throw new InvalidDataException("Cannot read patcher support limit; no changes made");
 }
}
'@
}
function Read-DllEol([string]$Path) { return [RosePatcherPeReaderV12]::ReadEol($Path) }
