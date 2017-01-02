set Factories; /*Üzemek*/
set Shops; /*Boltok*/
set Days; /*Napok*/
set Products; /*Gyártott Termékek*/

param OpeningTimes{D in Days,S in Shops}; /*Boltok napi nyitása*/
param WorkStarting{D in Days,F in Factories}; /*Üzemek napi kezdése*/
param Price{P in Products}; /*Egy termékfajta ára*/
param Distance{F in Factories,S in Shops}; /*Üzemek és Boltok távolsága*/
param Demand{S in Shops,P in Products}; /*Boltok kereslete*/
param Consumption; /*Autó fogyasztása*/
param FuelCost; /*Üzemanyag aktuális ára*/
param ProductionTime{P in Products}; /*Egy termék elõállításának idõtartama*/
param BigM:=150; 


var Produce{D in Days,F in Factories,P in Products},integer; /*Adott napon adott üzem adott termékbõl mennyit gyárt*/
var Deliver{D in Days,F in Factories,S in Shops,P in Products},integer>=0;/*Adott napon adott üzem adott boltba adott termékbõl mennyit dzállít*/
var DailyDelivery{D in Days,F in Factories,S in Shops},integer;/*Adott napon adott üzem adott boltba összesen hány terméket szállít*/
var ExistingDelivery{D in Days,F in Factories,S in Shops},binary;/*Adott napon adott üzem adott boltba szállít-e?*/
var Start{D in Days,F in Factories,P in Products}>=0;/*Adott napon adott üzemben termékfajták gyártásának kezdeti ideje*/
var Finish{D in Days,F in Factories,P in Products}>=0;/*Adott napon adott üzemben termékfajták gyártásának befejezési ideje*/
var Prec{D in Days,P1 in Products,P2 in Products,F in Factories},binary;/*Adott napon adott üzemben termékfajták precedenciája*/
var Alloc{D in Days,P in Products,F in Factories}, binary;/*Adott napon adott üzemben termékfajták gyártásának allokációja*/
var ProductionTimeProductSum{D in Days,P in Products,F in Factories};/*Adott napon adott üzemben adott termékfajtára fordított össz. idõ*/
var ProductionTimeFactorySum{D in Days,F in Factories};/*Adott napon adott üzemben a teljes termelésre fordított össz. idõ*/


s.t. production_matching_demand{D in Days,P in Products}:
	sum{F in Factories}(Produce[D,F,P])=sum{S in Shops}(Demand[S,P]);/*Napi igényt ki kell elégíteni.*/

s.t. deliveries{D in Days,S in Shops,P in Products}:
	Deliver[D,'F1',S,P]+Deliver[D,'F2',S,P]=Demand[S,P];/*Napi igényt a boltba el is kell juttatni.*/

s.t. deliver_only_avalible{D in Days,P in Products,F in Factories}:
	sum{S in Shops}(Deliver[D,F,S,P])=Produce[D,F,P];/*Csak azt lehet elszállítani, amit meg is termeltünk.*/

s.t. daily_delivery_sum{D in Days,F in Factories,S in Shops}:
	sum{P in Products}(Deliver[D,F,S,P])=DailyDelivery[D,F,S];/*Segédváltozó kiszámolása.*/

s.t. delivery_routes{D in Days,F in Factories,S in Shops}:
	ExistingDelivery[D,F,S]*sum{P in Products}(Demand[S,P])>=DailyDelivery[D,F,S];/*Melyik szállítási útvonal létezik valójában.*/

s.t. allocation{D in Days,P in Products}:
	sum{F in Factories} Alloc[D,P,F]*sum{S in Shops}(Demand[S,P])>=sum{S in Shops}(Demand[S,P]);/*Termékek allokációja az üzemekhez.*/

s.t. production_matching_allocation{D in Days,P in Products,F in Factories}:
	Alloc[D,P,F]<=Produce[D,F,P];/*Nincs allokálva, ha nem termelünk.*/

s.t. production_time_per_product_per_factory{D in Days,P in Products,F in Factories}:
	Produce[D,F,P]*ProductionTime[P]=ProductionTimeProductSum[D,P,F];/*Segédváltozó kiszámolása.*/

s.t. sequencing{D in Days,F in Factories,P1 in Products,P2 in Products: P1!=P2}:
	Prec[D,P1,P2,F]+Prec[D,P2,P1,F]>=Alloc[D,P1,F]+Alloc[D,P2,F]-1;/*Gyártási sorrend üzemenként.*/

s.t. timing{D in Days,F in Factories,P1 in Products, P2 in Products: P1!=P2}:
	Start[D,F,P2] >= Finish[D,F,P1] - BigM * (1 - Prec[D,P1,P2,F]);/*Amelyik megelõzi a másikat,annak elõbb vége, mint a másik kezdete.*/

s.t. processing_time{D in Days,F in Factories,P in Products}:
	Finish[D,F,P]=Start[D,F,P]+Produce[D,F,P]*ProductionTime[P];/*Idõzítések kiszámítása üzemenként.*/

s.t. production_time_per_factory{D in Days,F in Factories}:
	sum{P in Products}(ProductionTimeProductSum[D,P,F])=ProductionTimeFactorySum[D,F];/*Üzemenkénti összes termelés idõtartama.*/

s.t. deliver_in_time{D in Days,F in Factories,S in Shops}:
	WorkStarting[D,F]+ProductionTimeFactorySum[D,F]<=OpeningTimes[D,S]+BigM*(1-ExistingDelivery[D,F,S]);
/*Abban az esetben, ha az adott üzem szállít adott boltba, akkor az összes termeléssel el kell készülnünk az elõtt, hogy a bolt kinyitna.*/

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
