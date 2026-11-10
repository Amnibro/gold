import json,sys
D=['calc','price','type','mail','crypt','cad']
J=json.load(open('results.json'));R=[J[d] for d in D]
f=lambda n:f'{n:,}'
ms=lambda s:f'{s*1000:,.0f} ms' if s>=1 else f'{s*1000:,.1f} ms'
def sp(o,h):r=o/h;return f'{r:.1f}&times; faster' if r>=1.05 else (f'{1/r:.1f}&times; slower' if r<=0.95 else 'about even')
def pct(a,b):p=round(100*(a-b)/a);return f'{p}% fewer' if p>0 else f'{-p}% more'
rows=[];to=tg=th=0
for r in R:
    t=r['tokens'];to+=t['orig'];tg+=t['gold'];th+=t['helium'];tm=r['time']
    m=f"{f(r['match'])} / {f(r['cases'])}"+(f" ({f(r['exact'])} byte-identical)" if r['exact']!=r['match'] else ' byte-identical')
    rows.append(f'<tr class="grp"><td colspan="4">{r["product"].upper()}: {r["module"].upper()} ({r["orig_lang"].upper()})</td></tr>')
    rows.append(f'<tr><td>Output matches the original</td><td class="n" colspan="3">{m}</td></tr>')
    rows.append(f'<tr><td>Claude tokens to read the code</td><td class="n">{f(t["orig"])}</td><td class="n">Gold {f(t["gold"])} &middot; Helium {f(t["helium"])}</td><td class="n">Gold: {pct(t["orig"],t["gold"])}</td></tr>')
    rows.append(f'<tr><td>Run time ({f(r["reps"])} passes over the cases)</td><td class="n">{ms(tm["orig"])}</td><td class="n">{ms(tm["helium"])}</td><td class="n">{sp(tm["orig"],tm["helium"])}</td></tr>')
    x=r.get('extra',{'time':{}})
    for k,v in x['time'].items():
        if k in x.get('labels',{}):h=x['time'][x.get('he',{}).get(k,'helium')];rows.append(f'<tr><td>Same work, {x["labels"][k]} ({f(x["reps"])} passes)</td><td class="n">{ms(v)}</td><td class="n">{ms(h)}</td><td class="n">{sp(v,h)}</td></tr>')
print('\n'.join(rows))
print(f'TOTAL tokens orig={to} gold={tg} helium={th} gold_saving={round(100*(to-tg)/to)}%',file=sys.stderr)
