export const MM_PER={in:25.4,mm:1};
let SYS='us';try{SYS=localStorage.getItem('amnicad.sys')||'us';}catch{}
export const sys=()=>SYS;
export function setSys(s){SYS=s==='si'?'si':'us';try{localStorage.setItem('amnicad.sys',SYS);}catch{}}
export const docUnits=doc=>doc&&doc.units==='in'?'in':'mm';
export const mmPer=doc=>MM_PER[docUnits(doc)];
export function nf(v,d){if(v==null||!isFinite(v))return'—';const a=Math.abs(v),dd=d??(a>=1000?0:a>=100?1:a>=10?2:a>=1?3:a>=0.01?4:5);return((+v.toFixed(dd))||0).toLocaleString('en-US',{maximumFractionDigits:dd});}
export const Q={
len:{si:['mm',1],us:['in',1/25.4]},
area:{si:['mm²',1],us:['in²',1/645.16]},
vol:{si:['cm³',1e-3],us:['in³',1/16387.064]},
mass:{si:['kg',1],us:['lb',2.2046226]},
force:{si:['N',1],us:['lbf',0.22480894]},
press:{si:['MPa',1],us:['psi',145.03774]},
stress:{si:['MPa',1],us:['psi',145.03774]},
modulus:{si:['GPa',1e-3],us:['Msi',1.4503774e-4]},
torque:{si:['N·mm',1],us:['lbf·in',0.0088507458]},
temp:{si:['°C',1,0],us:['°F',1.8,32]},
dtemp:{si:['K',1],us:['°F',1.8]},
power:{si:['W',1],us:['BTU/hr',3.4121416]},
film:{si:['W/m²K',1],us:['BTU/hr·ft²·°F',0.17611016]},
cond:{si:['W/m·K',1],us:['BTU/hr·ft·°F',0.57782155]},
speed:{si:['m/s',1],us:['mph',2.2369363]},
dens:{si:['kg/m³',1],us:['lb/in³',3.6127292e-5]},
accel:{si:['m/s²',1],us:['ft/s²',3.2808399]},
freq:{si:['Hz',1],us:['Hz',1]},
pa:{si:['Pa',1],us:['psf',0.020885434]}};
export function conv(q,v,to){const u=Q[q][to];return v*u[1]+(u[2]||0);}
export function back(q,v,from){const u=Q[q][from];return(v-(u[2]||0))/u[1];}
export const unitOf=(q,s=SYS)=>Q[q][s][0];
export const toSI=(q,v)=>back(q,v,SYS);
export const fromSI=(q,v)=>conv(q,v,SYS);
export function one(q,vSI,s=SYS,d){return nf(conv(q,vSI,s),d)+' '+Q[q][s][0];}
export function dual(q,vSI,d){const a=SYS,b=a==='us'?'si':'us';return one(q,vSI,a,d)+' ('+one(q,vSI,b,d)+')';}
