using DrWatson
@quickactivate :benchmarks

include(helpersdir("data_aggr_helper.jl"))

using TOML
using DataFrames
using PrettyTables

const slurm_id = ARGS[1]
const sim_name = ARGS[2]

# TODO: Have meta config information be in a seperate toml
config_data = TOML.parsefile(get_config(sim_name, "cpu"))
meta_config = get_meta_config_info(config_data)
const meta_field_names = split(meta_config["fields"], ",")

# TODO: Meant as a basic data processing pipeline
# Can create multiple scripts to roughly process data in general ways
pretty_results = collect_results(aggdatadir(sim_name, slurm_id))

median_times = map(stage -> get_benchmark_headername(stage, "Median", "Time"), get_solver_stages())
table_header = vcat(["Task ID", "statsfile", "benchfile"], meta_field_names, median_times, ["nf"])

select!(pretty_results, table_header)

for time in median_times
  transform!(pretty_results, [time] => ByRow(x -> x / 1e9) => [time])
end

# TODO: Can choose other sorting methods
for field_name in reverse(meta_field_names)
  sort!(pretty_results, Symbol(field_name))
end

mkpath(tablesdir(sim_name, slurm_id))

# TODO: Can change this backened to be different from markdown
open(tablesdir(sim_name, slurm_id, "default_output.md"), "w") do results_file
  conf = set_pt_conf(tf = tf_markdown)
  pretty_table_with_conf(conf, results_file, pretty_results; header = table_header)
end
