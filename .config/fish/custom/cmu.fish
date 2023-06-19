if status is-interactive
	set ip "http://proxy.cmu.edu:3128"
	set -x http_proxy "$ip"
	set -x https_proxy "$ip"
	set -x HTTP_PROXY "$ip"
	set -x HTTPS_PROXY "$ip"

	conda deactivate	# preserves path order wrt dev env for tmux
	conda activate nsd-expts
end
