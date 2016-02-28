using DataFrames
using JuMP
using Clp

rrt = readtable("dat/rrt.csv")

month_names = vec([string('m', year, '_', month) for year=2016:2017,month=1:12])
month_pref = rrt[month_names]
month_pref = rrt[vec([string('m', year, '_', month) for year=2016:2017,month=1:12])]

# for i = 1:12
# 	rename!(rrt, "m2016_$i", i)
# end

# for i = 1:12
# 	rename!(rrt, "m2017_$i", i + 12)
# end

# rename!(rrt.colindex, [(symbol("m2016_$i")=>symbol("$i")) for i in 1:12])
# rename!(rrt, "m2016_1", "1")

priority_dict = ["preference" => 1.0,
				 "spanish" => 1.0,
				 "french" => 1.0,
				 "logistics" => 1.0,
				 "medofficer" => 1.0,
				 "pha" => 1.0,
				 "ICSpart" => 1.0,
				 "ICSlead" => 1.0,
				 "Response_primary" => 1.0,
				 "Response_leader" => 1.0]

tot_employ,total_vars = size(rrt)
tot_month = 24

m = Model()
@defVar(m, month_assgn[1:tot_employ, 1:tot_month], Bin)
@defVar(m, spanish_slack[1:tot_month] >= 0)
@defVar(m, french_slack[1:tot_month] >= 0)
@defVar(m, logistics_slack[1:tot_month] >= 0)
@defVar(m, medofficer_slack[1:tot_month] >= 0)
@defVar(m, pha_slack[1:tot_month] >= 0)
@defVar(m, ICSpart_slack[1:tot_month] >= 0)
@defVar(m, ICSlead_slack[1:tot_month] >= 0)
@defVar(m, Response_primary_slack[1:tot_month] >= 0)
@defVar(m, Response_leader_slack[1:tot_month] >= 0)
# @defExpr(m, expr[i=1:3], i*sum{x[j], j=1:3})
# @defExpr(m, tot_spanish[month=1:tot_month],
# 	sum{month_assgn[employ, month] * rrt[employ, "spanish"], employ=1:tot_employ})
# Employees serve according to preference
@addConstraint(m, no_pref_confl[employ=1:tot_employ,month=1:tot_month],
			   month_assgn[employ, month] + month_pref[employ, month] <= 1)
# Each group contains 40 people
@addConstraint(m, monthly_team_size[month=1:tot_month],
			   sum{month_assgn[employ, month], employ=1:tot_employ} >= 40)
# Two assignments per employee per year
@addConstraint(m, two_months_in_2016[employ=1:tot_employ],
			   sum(month_assgn[employ, 1:12]) == 2)
@addConstraint(m, two_months_in_2017[employ=1:tot_employ],
			   sum(month_assgn[employ, 13:24]) == 2)
# At least 4 spanish speakers every month
@addConstraint(m, spanish[month=1:tot_month],
	4.0 - AffExpr(month_assgn[:, month], float64(vector(rrt["spanish"])), 0.0) <= spanish_slack[month])
# At least 2 French Speakers every month
@addConstraint(m, french[month=1:tot_month],
	2.0 - AffExpr(month_assgn[:, month], float64(vector(rrt["french"])), 0.0) <= french_slack[month])
# At least 1 logistics employee every month
@addConstraint(m, logistics[month=1:tot_month],
	1.0 - AffExpr(month_assgn[:, month], float64(vector(rrt["logistics"])), 0.0) <= logistics_slack[month])
# At least 4 medical officers every month
@addConstraint(m, medofficer[month=1:tot_month],
	4.0 - AffExpr(month_assgn[:, month], float64(vector(rrt["medofficer"])), 0.0) <= medofficer_slack[month])
# Get PHA within range
@addConstraint(m, pha[month=1:tot_month],
	10.0 - AffExpr(month_assgn[:, month], float64(vector(rrt["pha"])), 0.0) <= pha_slack[month])
# At least 10 have served in ICS structure
@addConstraint(m, ICSpart[month=1:tot_month],
	10.0 - AffExpr(month_assgn[:, month], float64(vector(rrt["ICSpart"])), 0.0) <= ICSpart_slack[month])
# At least 2 have served in ICS leader
@addConstraint(m, ICSlead[month=1:tot_month],
	2.0 - AffExpr(month_assgn[:, month], float64(vector(rrt["ICSlead"])), 0.0) <= ICSlead_slack[month])
# CIO Primary Responder
@addConstraint(m, Response_primary[month=1:tot_month],
	20.0 - AffExpr(month_assgn[:, month], float64(vector(rrt["Response_primary"])), 0.0) <= Response_primary_slack[month])
# CIO Primary Responder
@addConstraint(m, Response_leader[month=1:tot_month],
	5.0 - AffExpr(month_assgn[:, month], float64(vector(rrt["Response_leader"])), 0.0) <= Response_leader_slack[month])

setObjective(m, :Min,
			 sum(spanish_slack[month]) * priority_dict["spanish"] +
			 sum(french_slack[month]) * priority_dict["french"] +
			 sum(logistics_slack[month]) * priority_dict["logistics"] +
			 sum(medofficer_slack[month]) * priority_dict["medofficer"] +
			 sum(pha_slack[month]) * priority_dict["pha"] +
			 sum(ICSpart_slack[month]) * priority_dict["ICSpart"] +
			 sum(ICSlead_slack[month]) * priority_dict["ICSlead"] +
			 sum(Response_primary_slack[month]) * priority_dict["Response_primary"] +
			 sum(Response_leader_slack[month]) * priority_dict["Response_leader"]
			)

status = solve(m)