set Factories; /*�zemek*/
set Shops; /*Boltok*/
set Days; /*Napok*/
set Products; /*Gy�rtott Term�kek*/

param OpeningTimes{D in Days,S in Shops}; /*Boltok napi nyit�sa*/
param WorkStarting{D in Days,F in Factories}; /*�zemek napi kezd�se*/
param Price{P in Products}; /*Egy term�kfajta �ra*/
param Distance{F in Factories,S in Shops}; /*�zemek �s Boltok t�vols�ga*/
param Demand{S in Shops,P in Products}; /*Boltok kereslete*/
param Consumption; /*Aut� fogyaszt�sa*/
param FuelCost; /*�zemanyag aktu�lis �ra*/
param ProductionTime{P in Products}; /*Egy term�k el��ll�t�s�nak id�tartama*/
param BigM:=150; 


var Produce{D in Days,F in Factories,P in Products},integer; /*Adott napon adott �zem adott term�kb�l mennyit gy�rt*/
var Deliver{D in Days,F in Factories,S in Shops,P in Products},integer>=0;/*Adott napon adott �zem adott boltba adott term�kb�l mennyit dz�ll�t*/
var DailyDelivery{D in Days,F in Factories,S in Shops},integer;/*Adott napon adott �zem adott boltba �sszesen h�ny term�ket sz�ll�t*/
var ExistingDelivery{D in Days,F in Factories,S in Shops},binary;/*Adott napon adott �zem adott boltba sz�ll�t-e?*/
var Start{D in Days,F in Factories,P in Products}>=0;/*Adott napon adott �zemben term�kfajt�k gy�rt�s�nak kezdeti ideje*/
var Finish{D in Days,F in Factories,P in Products}>=0;/*Adott napon adott �zemben term�kfajt�k gy�rt�s�nak befejez�si ideje*/
var Prec{D in Days,P1 in Products,P2 in Products,F in Factories},binary;/*Adott napon adott �zemben term�kfajt�k precedenci�ja*/
var Alloc{D in Days,P in Products,F in Factories}, binary;/*Adott napon adott �zemben term�kfajt�k gy�rt�s�nak allok�ci�ja*/
var ProductionTimeProductSum{D in Days,P in Products,F in Factories};/*Adott napon adott �zemben adott term�kfajt�ra ford�tott �ssz. id�*/
var ProductionTimeFactorySum{D in Days,F in Factories};/*Adott napon adott �zemben a teljes termel�sre ford�tott �ssz. id�*/


s.t. production_matching_demand{D in Days,P in Products}:
	sum{F in Factories}(Produce[D,F,P])=sum{S in Shops}(Demand[S,P]);/*Napi ig�nyt ki kell el�g�teni.*/

s.t. deliveries{D in Days,S in Shops,P in Products}:
	Deliver[D,'F1',S,P]+Deliver[D,'F2',S,P]=Demand[S,P];/*Napi ig�nyt a boltba el is kell juttatni.*/

s.t. deliver_only_avalible{D in Days,P in Products,F in Factories}:
	sum{S in Shops}(Deliver[D,F,S,P])=Produce[D,F,P];/*Csak azt lehet elsz�ll�tani, amit meg is termelt�nk.*/

s.t. daily_delivery_sum{D in Days,F in Factories,S in Shops}:
	sum{P in Products}(Deliver[D,F,S,P])=DailyDelivery[D,F,S];/*Seg�dv�ltoz� kisz�mol�sa.*/

s.t. delivery_routes{D in Days,F in Factories,S in Shops}:
	ExistingDelivery[D,F,S]*sum{P in Products}(Demand[S,P])>=DailyDelivery[D,F,S];/*Melyik sz�ll�t�si �tvonal l�tezik val�j�ban.*/

s.t. allocation{D in Days,P in Products}:
	sum{F in Factories} Alloc[D,P,F]*sum{S in Shops}(Demand[S,P])>=sum{S in Shops}(Demand[S,P]);/*Term�kek allok�ci�ja az �zemekhez.*/

s.t. production_matching_allocation{D in Days,P in Products,F in Factories}:
	Alloc[D,P,F]<=Produce[D,F,P];/*Nincs allok�lva, ha nem termel�nk.*/

s.t. production_time_per_product_per_factory{D in Days,P in Products,F in Factories}:
	Produce[D,F,P]*ProductionTime[P]=ProductionTimeProductSum[D,P,F];/*Seg�dv�ltoz� kisz�mol�sa.*/

s.t. sequencing{D in Days,F in Factories,P1 in Products,P2 in Products: P1!=P2}:
	Prec[D,P1,P2,F]+Prec[D,P2,P1,F]>=Alloc[D,P1,F]+Alloc[D,P2,F]-1;/*Gy�rt�si sorrend �zemenk�nt.*/

s.t. timing{D in Days,F in Factories,P1 in Products, P2 in Products: P1!=P2}:
	Start[D,F,P2] >= Finish[D,F,P1] - BigM * (1 - Prec[D,P1,P2,F]);/*Amelyik megel�zi a m�sikat,annak el�bb v�ge, mint a m�sik kezdete.*/

s.t. processing_time{D in Days,F in Factories,P in Products}:
	Finish[D,F,P]=Start[D,F,P]+Produce[D,F,P]*ProductionTime[P];/*Id�z�t�sek kisz�m�t�sa �zemenk�nt.*/

s.t. production_time_per_factory{D in Days,F in Factories}:
	sum{P in Products}(ProductionTimeProductSum[D,P,F])=ProductionTimeFactorySum[D,F];/*�zemenk�nti �sszes termel�s id�tartama.*/

s.t. deliver_in_time{D in Days,F in Factories,S in Shops}:
	WorkStarting[D,F]+ProductionTimeFactorySum[D,F]<=OpeningTimes[D,S]+BigM*(1-ExistingDelivery[D,F,S]);
/*Abban az esetben, ha az adott �zem sz�ll�t adott boltba, akkor az �sszes termel�ssel el kell k�sz�ln�nk az el�tt, hogy a bolt kinyitna.*/

maximize profit{D in Days}: sum{P in Products,F in Factories,S in Shops}(Deliver[D,F,S,P]*Price[P])-sum{F in Factories,S in Shops}(ExistingDelivery[D,F,S])*Distance[F,S]*(Consumption/100)*FuelCost;

solve;


for {D in Days}{
	printf "%4s\n",D;
	printf "---------------------------------------\n";
	printf "    ";
	for {S in Shops} printf "%12s",S;
	printf "\n";
	for {F in Factories}{
		printf "%s",F;
		for {S in Shops} printf "%12d\t",DailyDelivery[D,F,S];
		printf "\n";
	}
	printf "---------------------------------------\n\n";
}

for {D in Days}{
	printf "%4s\n",D;
	printf "---------------------------------------\n";
	printf "    ";
	for {S in Shops} printf "%12s",S;
	printf "\n";
	for {F in Factories}{
		printf "%s",F;
		for {S in Shops} printf "%12d\t",ExistingDelivery[D,F,S];
		printf "\n";
	}
	printf "---------------------------------------\n\n";
}

for {D in Days}{
	printf "%4s\n",D;
	printf "/-*-\/-*-\/-*-\/-*-\/-*-\/-*-\/-*-\/-*-\\\n";
	for {P in Products}{
		printf "%4s\n",P;
		printf "---------------------------------------\n";
		printf "    ";
		for {S in Shops} printf "%12s",S;
		printf "\n";
		for {F in Factories}{
			printf "%s",F;
			for {S in Shops} printf "%12d\t",Deliver['M',F,S,P];
			printf "\n";
		}
		printf "---------------------------------------\n\n";
	}
}
