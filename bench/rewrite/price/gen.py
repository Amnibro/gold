import random
random.seed(9)
names=["Organic Whole Milk","Kraft Mac & Cheese","Bananas","Greek Yogurt Vanilla","Tide Pods","Cheerios","Chicken Breast","Coca-Cola 12pk","Sourdough Bread","Large Eggs","Peanut Butter Creamy","Frozen Pizza Pepperoni","Olive Oil Extra Virgin","Paper Towels","Ground Coffee"]
sizes=["12 OZ","1 GAL","16 fl oz","2 LB","500 g","1.5 L","24 ct","6 pk","32oz","750ml","0,5 kg","3 lbs"]
def price():
    d=random.randint(0,99) if random.random()<.8 else random.randint(100,1299); c=random.randint(0,99)
    k=random.random()
    if k<.3: return "$%d.%02d"%(d,c)
    if k<.45: return "%d.%02d"%(d,c)
    if k<.55: return "$%d %02d"%(d,c)
    if k<.62: return "%d for $%d.%02d"%(random.randint(2,5),d,c)
    if k<.68: return "%d/$%d"%(random.randint(2,4),d)
    if k<.74: return "%d %02d"%(d%100,c)
    if k<.8: return "%d¢"%c
    if k<.86: return "$%d"%d
    if k<.9: return "%d,%02d"%(d,c)
    return "%d%02d"%(random.randint(1,9),c)
def tag():
    L=[];y=10
    def add(t,h):
        nonlocal y; x=random.randint(0,40); L.append((t,x,y,x+len(t)*h//2,y+h)); y+=h+random.randint(2,8)
    if random.random()<.5: add(random.choice(["SALE","SAVE $1.00","Everyday Low Price","ROLLBACK","Was $4.99","With Card","BOGO"]),random.randint(8,20))
    add(random.choice(names)+(" "+random.choice(sizes) if random.random()<.6 else ""),random.randint(10,24))
    if random.random()<.25:
        d=random.randint(1,19);c=random.randint(0,99);h=random.randint(40,70);x=60
        L.append(("$%d"%d,x,y,x+h//2*len(str(d)),y+h)); L.append(("%02d"%c,x+h//2*len(str(d))+2,y,x+h//2*len(str(d))+2+h//2,y+h//2)); y+=h+5
    else: add(price(),random.randint(30,70))
    if random.random()<.6: add("$%d.%02d / %s"%(random.randint(0,3),random.randint(0,99),random.choice(["oz","lb","100 g","ea","fl oz","qt"])),random.randint(6,12))
    if random.random()<.4: add(random.choice(["UPC 0%011d"%random.randint(0,10**10),"SKU 12345","Item # 4421","IIIlll1||IIl","PLU 4011","Aisle 7"]),random.randint(5,10))
    if random.random()<.3: add(random.choice(sizes),random.randint(8,14))
    random.shuffle(L) if random.random()<.2 else None
    return "\x1e".join("\x1f".join(map(str,l)) for l in L)
print(""); 
for i in range(399): print(tag())
