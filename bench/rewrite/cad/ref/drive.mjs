import * as U from './units.js';
import {readFileSync} from 'fs';
const num=x=>x==='inf'?Infinity:+x;
const C=readFileSync(0,'utf8').trim().split('\n').map(l=>l.split('\t'));
const run=f=>f[0]==='nf'?U.nf(num(f[1]),+f[2]===-1?undefined:+f[2]):f[0]==='one'?U.one(f[1],num(f[2]),f[3],+f[4]===-1?undefined:+f[4]):U.dual(f[1],num(f[2]),+f[3]===-1?undefined:+f[3]);
const reps=+(process.env.REPS||0);
if(!reps){console.log(C.map(run).join('\n'));}else{let t=0;for(let r=0;r<reps;r++)for(const f of C)t+=run(f).length;console.log(t);}
