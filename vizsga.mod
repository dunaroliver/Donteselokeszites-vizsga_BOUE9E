set Factories;
set Shops;
set Days;
set Products;

param OpeningTimes{D in Days,S in Shops};
param WorkStarting{D in Days,F in Factories};
param Price{P in Products};
param Distance{F in Factories,S in Shops};
param Demand{S in Shops,P in Products};
param DailyMultiplier{D in Days};
param Consumption;
param FuelCost;

var Produce{D in Days,F in Factories,P in Products},integer;
var Deliver{D in Days,F in Factories,S in Shops,P in Products},integer;
var DailyDelivery{D in Days,F in Factories,S in Shops},integer;
var DailyDemand{D in Days,P in Products},integer;
var ExistingDelivery{D in Days,F in Factories,S in Shops},binary;

s.t. daily_demand_sum{D in Days,P in Products}:
	sum{S in Shops}(Demand[S,P])=DailyDemand[D,P];

s.t. production_matching_demand{D in Days,P in Products}:
	sum{F in Factories}(Produce[D,F,P])=DailyDemand[D,P];

s.t. deliveries{D in Days,S in Shops,P in Products}:
	Deliver[D,'F1',S,P]+Deliver[D,'F2',S,P]=Demand[S,P];

s.t. deliver_only_avalible{D in Days,P in Products,F in Factories}:
	sum{S in Shops}(Deliver[D,F,S,P])=Produce[D,F,P];

s.t. daily_delivery_sum{D in Days,F in Factories,S in Shops}:
	sum{P in Products}(Deliver[D,F,S,P])=DailyDelivery[D,F,S];

s.t. delivery_routes{D in Days,F in Factories,S in Shops}:
	ExistingDelivery[D,F,S]*sum{P in Products}(Demand[S,P])>=DailyDelivery[D,F,S];

s.t. one_delivery_min{F in Factories}:
	sum{D in Days,S in Shops}(ExistingDelivery[D,F,S])>=5;

maximize profit{D in Days}: sum{P in Products,F in Factories,S in Shops}(Deliver[D,F,S,P]*Price[P])-sum{F in Factories,S in Shops}(ExistingDelivery[D,F,S])*Distance[F,S]*(Consumption/100)*FuelCost;
