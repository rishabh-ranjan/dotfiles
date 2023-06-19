if status is-interactive
	conda deactivate	# preserves path order wrt dev env for tmux
	conda activate nsd-expts
end
