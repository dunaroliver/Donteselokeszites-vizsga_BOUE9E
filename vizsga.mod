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
param ProductionTime{P in Products}; /*Egy term�k elo�ll�t�s�nak idotartama*/
param ProductDeadline{P in Products}; /*Term�kek elk�sz�t�s�nek hat�rideje*/
param AvgSpeed;
param MinProductNumber;
param BigM:=150; 


var Produce{D in Days,F in Factories,P in Products},integer; /*Adott napon adott �zem adott term�kbol mennyit gy�rt*/
var Deliver{D in Days,F in Factories,S in Shops,P in Products},integer>=0;/*Adott napon adott �zem adott boltba adott term�kbol mennyit sz�ll�t*/
var DailyDelivery{D in Days,F in Factories,S in Shops},integer;/*Adott napon adott �zem adott boltba �sszesen h�ny term�ket sz�ll�t*/
var ExistingDelivery{D in Days,F in Factories,S in Shops},binary;/*Adott napon adott �zem adott boltba sz�ll�t-e?*/
var Start{D in Days,F in Factories,P in Products}>=0;/*Adott napon adott �zemben term�kfajt�k gy�rt�s�nak kezdeti ideje*/
var Finish{D in Days,F in Factories,P in Products}>=0;/*Adott napon adott �zemben term�kfajt�k gy�rt�s�nak befejez�si ideje*/
var Prec{D in Days,P1 in Products,P2 in Products,F in Factories},binary;/*Adott napon adott �zemben term�kfajt�k precedenci�ja*/
var Alloc{D in Days,P in Products,F in Factories}, binary;/*Adott napon adott �zemben term�kfajt�k gy�rt�s�nak allok�ci�ja*/
var ProductionTimeProductSum{D in Days,P in Products,F in Factories};/*Adott napon adott �zemben adott term�kfajt�ra ford�tott �ssz. ido*/
var ProductionTimeFactorySum{D in Days,F in Factories};/*Adott napon adott �zemben a teljes termel�sre ford�tott �ssz. ido*/



s.t. production_matching_demand{D in Days,P in Products}:
	sum{F in Factories}(Produce[D,F,P])=sum{S in Shops}(Demand[S,P]);/*Napi ig�nyt ki kell el�g�teni.*/

s.t. deliveries{D in Days,S in Shops,P in Products}:
	Deliver[D,'F1',S,P]+Deliver[D,'F2',S,P]=Demand[S,P];/*Napi ig�nyt a boltba el is kell juttatni.*/

s.t. deliver_only_avalible{D in Days,P in Products,F in Factories}:
	sum{S in Shops}(Deliver[D,F,S,P])=Produce[D,F,P];/*Csak azt lehet elsz�ll�tani, amit meg is termelt�nk.*/

s.t. daily_delivery_sum{D in Days,F in Factories,S in Shops}:
	sum{P in Products}(Deliver[D,F,S,P])=DailyDelivery[D,F,S];/*Seg�dv�ltoz� kisz�mol�sa.*/

s.t. daily_delivery_min{D in Days,F in Factories,S in Shops}:
	DailyDelivery[D,F,S]>=MinProductNumber*ExistingDelivery[D,F,S];/*Minimum n-db s�tem�nyt kell sz�ll�tanunk. K�l�n 1db-ot nem visz�nk el egy fajt�b�l.*/

s.t. delivery_routes{D in Days,F in Factories,S in Shops}:
	ExistingDelivery[D,F,S]*sum{P in Products}(Demand[S,P])>=DailyDelivery[D,F,S];/*Melyik sz�ll�t�si �tvonal l�tezik val�j�ban.*/

s.t. allocation{D in Days,P in Products}:
	sum{F in Factories} Alloc[D,P,F]*sum{S in Shops}(Demand[S,P])>=sum{S in Shops}(Demand[S,P]);/*Term�kek allok�ci�ja az �zemekhez.*/

s.t. production_matching_allocation{D in Days,P in Products,F in Factories}:
	Alloc[D,P,F]*BigM>=Produce[D,F,P];/*Nincs allok�lva, ha nem termel�nk.*/

s.t. production_time_per_product_per_factory{D in Days,P in Products,F in Factories}:
	Produce[D,F,P]*ProductionTime[P]=ProductionTimeProductSum[D,P,F];/*Seg�dv�ltoz� kisz�mol�sa.*/

s.t. sequencing{D in Days,F in Factories,P1 in Products,P2 in Products: P1!=P2}:
	Prec[D,P1,P2,F]+Prec[D,P2,P1,F]>=Alloc[D,P1,F]+Alloc[D,P2,F]-1;/*Gy�rt�si sorrend �zemenk�nt.*/

s.t. timing{D in Days,F in Factories,P1 in Products, P2 in Products: P1!=P2}:
	Start[D,F,P2] >= Finish[D,F,P1] - BigM * (1 - Prec[D,P1,P2,F]);/*Amelyik megelozi a m�sikat,annak elobb v�ge, mint a m�sik kezdete.*/

s.t. processing_time{D in Days,F in Factories,P in Products}:
	Finish[D,F,P]=Start[D,F,P]+Produce[D,F,P]*ProductionTime[P];/*Idoz�t�sek kisz�m�t�sa �zemenk�nt.*/

s.t. deadlines{D in Days,F in Factories,P in Products}:
	Finish[D,F,P]<=ProductDeadline[P];/*Term�kek gy�rt�s�t hat�rid� el�tt be kell fejezni.*/

s.t. production_time_per_factory{D in Days,F in Factories}:
	sum{P in Products}(ProductionTimeProductSum[D,P,F])=ProductionTimeFactorySum[D,F];/*�zemenk�nti �sszes termel�s idotartama.*/

s.t. deliver_in_time{D in Days,F in Factories,S in Shops}:
	WorkStarting[D,F]+ProductionTimeFactorySum[D,F]+(Distance[F,S]/AvgSpeed)<=OpeningTimes[D,S]+BigM*(1-(ExistingDelivery[D,F,S]));
/*Abban az esetben, ha az adott �zem sz�ll�t adott boltba, akkor az �sszes termel�ssel �s sz�ll�t�ssal el kell k�sz�ln�nk az elott, hogy a bolt kinyitna.*/

maximize profit{D in Days}: sum{P in Products,F in Factories,S in Shops}(Deliver[D,F,S,P]*Price[P])-sum{F in Factories,S in Shops}(ExistingDelivery[D,F,S]*Distance[F,S]*(Consumption/100)*FuelCost);

solve;

printf "\n\nDaily Product Deliveries:\n\n";
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

printf "\n\nDaily Deliveries:\n\n";
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

printf "\n\nDaily Deliveries Per Product:\n\n";
for {D in Days}{
	printf "%4s\n",D;
	printf "*************************************************\n";
	for {P in Products}{
		printf "%4s\n",P;
		printf "---------------------------------------\n";
		printf "    ";
		for {S in Shops} printf "%12s",S;
		printf "\n";
		for {F in Factories}{
			printf "%s",F;
			for {S in Shops} printf "%12d\t",Deliver[D,F,S,P];
			printf "\n";
		}
		printf "---------------------------------------\n\n";
	}
}

printf "\n\nDaily Production Per Product:\n\n";
for {P in Products}{
	printf "%4s\n",P;
	printf "*************************************************\n";
	printf "           ";
	for{D in Days} printf"%s\t   ",D;
	printf "\n";
	for {F in Factories}{
		printf "%s",F;
		for{D in Days} printf "\t %4d",Produce[D,F,P];
		printf "\n";
	}
	printf "---------------------------------------\n\n";
}

printf "\n\nDaily Precedence Matrix:\n\n";
for {D in Days}{
	printf "%4s\n",D;
	printf "*************************************************\n";
	for {F in Factories}{
		printf "%s:\n",F;
		for {P in Products} printf "\t   %s",P;
		printf "\n";
		for {P1 in Products}{
			printf "%s\t\t",P1;
			for {P2 in Products} printf "%1d\t\t",Prec[D,P1,P2,F];
			printf "\n";
		}
		printf "\n";
	}
}
