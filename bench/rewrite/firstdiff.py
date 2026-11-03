import sys,re,subprocess
d,exe,ids=sys.argv[1],sys.argv[2],[int(x) for x in sys.argv[3].split(',')]
c=open(d+'/cases.txt').read().split('\n');a=open(d+'/ref.out').read().split('\n')
for i in ids:
    o=subprocess.run([exe],input=(c[i]+'\n').encode(),capture_output=True,cwd=d).stdout.decode().rstrip('\n');r=a[i]
    j=next((k for k in range(min(len(o),len(r))) if o[k]!=r[k]),min(len(o),len(r)))
    print(f"#{i} @{j}/{len(r)} he:…{o[max(0,j-60):j+60]}\n      ref:…{r[max(0,j-60):j+60]}\n   in: {c[i][:400]}")
