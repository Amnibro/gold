import * as U from './units.js';
import {readFileSync} from 'fs';
const out=[];
for(const l of readFileSync('cases.txt','utf8').trim().split('\n')){const f=l.split('\t');const num=x=>x==='inf'?Infinity:+x;
if(f[0]==='nf')out.push(U.nf(num(f[1]),+f[2]===-1?undefined:+f[2]));
else if(f[0]==='one')out.push(U.one(f[1],num(f[2]),f[3],+f[4]===-1?undefined:+f[4]));
else out.push(U.dual(f[1],num(f[2]),+f[3]===-1?undefined:+f[3]));}
console.log(out.join('\n'));
