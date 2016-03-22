DEBUG :=
USE_GUILE :=
BUFFERING := 1
IGNORE_UNREPRESENTABLE_CHARACTERS := 1

ifneq '$(USE_GUILE)' ''
 ifeq '$(strip $(filter guile, $(.FEATURES)))' ''
  $(error USE_GUILE is set, but this make does not support it)
 endif
endif



# Original hello world
PROG := ++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.


# A slightly more complex variant that often triggers interpreter bugs
# https://esolangs.org/wiki/Brainfuck
#PROG := >++++++++[-<+++++++++>]<.>>+>-[+]++>++>+++[>[->+++<<+++>]<<]>-----.>-> +++..+++.>-.<<+[>[+>+]>>]<--------------.>>.+++.------.--------.>+.>+.


# Powers of two (Doesn't terminate)
# http://www.hevanet.com/cristofd/brainfuck/short.b
#PROG := >++++++++++>>+<+[[+++++[>++++++++<-]>.<++++++[>--------<-]+<<]>.>[->[ <++>-[<++>-[<++>-[<++>-[<-------->>[-]++<-[<++>-]]]]]]<[>+<-]+>>]<<]

# Fibonacci numbers (Doesn't terminate)
# http://www.hevanet.com/cristofd/brainfuck/short.b
#PROG := >++++++++++>+>+[ [+++++[>++++++++<-]>.<++++++[>--------<-]+<<<]>.>>[ [-]<[>+<-]>>[<<+>+>-]<[>+<-[>+<-[>+<-[>+<-[>+<-[>+<- [>+<-[>+<-[>+<-[>[-]>+>+<<<-[>+<-]]]]]]]]]]]+>>> ]<<< ]


# Fizzbuzz
# http://nue2004.info/program/fizzbuzz_bf/
#PROG := ++++++++++++[->++++++>+++++++++>+++++>++++++++++>++++++++++>+++>>>>>>++++++++<<<<<<<<<<<<]>-->--->++ ++++>--->++>---->>>>+++>+++++>++++[>>>+[-<<[->>+>+<<<]>>>[-<<<+>>>]+<[[-]>-<<[->+>+<<]>>[-<<+>>]+<[[ -]>-<<<+>->]>[-<<<--------->+++++++++>>>>>+<<<]<]>[-<+++++++[<<+++++++>>-]<++++++++>>]>>>]<<<<<<[<<< <]>-[-<<+>+>]<[->+<]+<[[-]>-<]>[->+++<<<<<<<<<.>.>>>..>>+>>]>>-[-<<<+>+>>]<<[->>+<<]+<[[-]>-<]>[->>+ ++++<<<<<<<<.>.>..>>+>>]<+<[[-]>-<]>[->>>>>[>>>>]<<<<[.<<<<]<]<<.>>>>>>-]




ifneq '$(USE_GUILE)' ''
 c_newline := $(guile (integer->char 10))
else
 c_newline :=
endif
c_sharp := \#
c_dollar := $$
c_percent := %
c_comma := ,
c_bracket_opening := (
c_bracket_closing := )
c_backslash := $(strip \ )



PROG_SEP := \
	$(subst >,> , \
		$(subst <,< , \
			$(subst +,+ , \
				$(subst -,- , \
					$(subst .,. , \
						$(subst $(c_comma),$(c_comma) , \
							$(subst [,[ , \
								$(subst ],] , \
									$(PROG) \
								) \
							) \
						) \
					) \
				) \
			) \
		) \
	)




# Combines input lists
# Arguments:
#   $1: list 1
#   $2: list 2
# Example:
#   $(call combine, a b, x y z)
#     => ax ay az bx by bz
combine = $(foreach i, $1, $(addprefix $i, $2))

# Strips leading zero
stripzero = $(patsubst 0%,%,$1)

# Generates number line
# Arguments:
#   $1: Numbers of the base
generate_number_line = \
	$(call stripzero, \
		$(call stripzero, \
			$(call combine, $1, \
				$(call combine, $1, \
					$1 \
				) \
			) \
		) \
	)

# 0 to 999
number_line := $(strip $(call generate_number_line, 0 1 2 3 4 5 6 7 8 9))

# 2 to 999
number_line_from_2 := $(wordlist 3, $(words $(number_line)), $(number_line))

# Adds 1 to the input number
# Arguments:
#   $1: Number to be added
#       [0, 998]
plus_1 = \
	$(if $(strip $(filter-out 0, $1)), \
		$(word $1, \
			$(number_line_from_2) \
		), \
		1 \
	)

# Subtracts 1 from the input number
# Arguments:
#   $1: Number to be subtracted
#       [1, 999]
minus_1 = \
	$(word $1, \
		$(number_line) \
	)



define do_>
 data_head := $$(strip $$(data_head) $$(data_cur))
 data_cur := $$(strip $$(firstword $$(data_tail)))
 data_tail := $$(strip $$(wordlist 2, $$(words $$(data_tail)), $$(data_tail)))
 $$(if $$(data_cur), , $$(eval data_cur := 0))
endef


define do_<
 data_tail := $$(strip $$(data_cur) $$(data_tail))
 $$(if $$(strip $$(filter-out 0, $$(words $$(data_head)))), \
	$$(eval data_cur := $$(strip $$(word $$(words $$(data_head)), $$(data_head)))) \
	$$(eval data_head := $$(strip $$(wordlist 1, $$(call minus_1, $$(words $$(data_head))), $$(data_head)))), \
	$$(eval data_head :=) \
	$$(eval data_cur := 0) \
 )
endef


define do_+
 data_cur := \
	$$(strip \
		$$(if $$(strip $$(filter-out 255, $$(data_cur))), \
			$$(call plus_1, $$(data_cur)), \
			0 \
		) \
	)
endef


define do_-
 data_cur := \
	$$(strip \
		$$(if $$(strip $$(filter-out 0, $$(data_cur))), \
			$$(call minus_1, $$(data_cur)), \
			255 \
		) \
	)
endef


define do_.
 print_stack := $$(strip $$(print_stack) $$(data_cur))
 ifneq '$(USE_GUILE)' ''
  $$(eval $$(call mkres))
  $$(guile (display "$$(RES)") (flush-all-ports))
 else
  ifeq '$(BUFFERING)' ''
   $$(eval $$(call flush))
  endif
 endif
endef


define do_comma
 ifneq '$(DEBUG)' ''
  $$(warning Doing $$(c_comma))
 endif
 ifneq '$(USE_GUILE)' ''
  data_cur := $$(guile (char->integer (read-char (current-input-port))))
 endif
endef


define do_[
 garbage := \
	$$(if $$(strip $$(filter 0, $$(data_cur))), \
		$$(eval n_of_]s_to_skip := 1), \
		$$(eval [_idxs_stack := $$(idx) $$([_idxs_stack)) \
	)
endef


define do_]
 idx_[ := $$(word 1, $$([_idxs_stack))
 [_idxs_stack := $$(wordlist 2, $$(words $$([_idxs_stack)), $$([_idxs_stack))
 ifneq '$(DEBUG)' ''
  $$(warning idx_[: $$(idx_[))
 endif
 idx_next := $$(idx_[)
endef



define mkres
 RES :=
ifneq '$(USE_GUILE)' ''
 garbage := \
	$$(foreach i, $$(print_stack), \
		$$(eval RES:=$$$$(RES)$$(if $$(filter 10,$$(i)),$$$$(c_newline),$$(guile (integer->char $$(i))))) \
	)
else
 garbage := \
	$$(foreach i, $$(print_stack), \
		$$(eval RES:=$$$$(RES)$$(if $$(filter 10,$$(i)),$$$$(c_newline),$$(if $$(filter 32,$$(i)), ,$$(if $$(filter 33,$$(i)),!,$$(if $$(filter 34,$$(i)),",$$(if $$(filter 35,$$(i)),$$$$(c_sharp),$$(if $$(filter 36,$$(i)),$$$$(c_dollar),$$(if $$(filter 37,$$(i)),$$$$(c_percent),$$(if $$(filter 38,$$(i)),&,$$(if $$(filter 39,$$(i)),',$$(if $$(filter 40,$$(i)),$$$$(c_bracket_opening),$$(if $$(filter 41,$$(i)),$$$$(c_bracket_closing),$$(if $$(filter 42,$$(i)),*,$$(if $$(filter 43,$$(i)),+,$$(if $$(filter 44,$$(i)),$$$$(c_comma),$$(if $$(filter 45,$$(i)),-,$$(if $$(filter 46,$$(i)),.,$$(if $$(filter 47,$$(i)),/,$$(if $$(filter 48,$$(i)),0,$$(if $$(filter 49,$$(i)),1,$$(if $$(filter 50,$$(i)),2,$$(if $$(filter 51,$$(i)),3,$$(if $$(filter 52,$$(i)),4,$$(if $$(filter 53,$$(i)),5,$$(if $$(filter 54,$$(i)),6,$$(if $$(filter 55,$$(i)),7,$$(if $$(filter 56,$$(i)),8,$$(if $$(filter 57,$$(i)),9,$$(if $$(filter 58,$$(i)),:,$$(if $$(filter 59,$$(i)),;,$$(if $$(filter 60,$$(i)),<,$$(if $$(filter 61,$$(i)),=,$$(if $$(filter 62,$$(i)),>,$$(if $$(filter 63,$$(i)),?,$$(if $$(filter 64,$$(i)),@,$$(if $$(filter 65,$$(i)),A,$$(if $$(filter 66,$$(i)),B,$$(if $$(filter 67,$$(i)),C,$$(if $$(filter 68,$$(i)),D,$$(if $$(filter 69,$$(i)),E,$$(if $$(filter 70,$$(i)),F,$$(if $$(filter 71,$$(i)),G,$$(if $$(filter 72,$$(i)),H,$$(if $$(filter 73,$$(i)),I,$$(if $$(filter 74,$$(i)),J,$$(if $$(filter 75,$$(i)),K,$$(if $$(filter 76,$$(i)),L,$$(if $$(filter 77,$$(i)),M,$$(if $$(filter 78,$$(i)),N,$$(if $$(filter 79,$$(i)),O,$$(if $$(filter 80,$$(i)),P,$$(if $$(filter 81,$$(i)),Q,$$(if $$(filter 82,$$(i)),R,$$(if $$(filter 83,$$(i)),S,$$(if $$(filter 84,$$(i)),T,$$(if $$(filter 85,$$(i)),U,$$(if $$(filter 86,$$(i)),V,$$(if $$(filter 87,$$(i)),W,$$(if $$(filter 88,$$(i)),X,$$(if $$(filter 89,$$(i)),Y,$$(if $$(filter 90,$$(i)),Z,$$(if $$(filter 91,$$(i)),[,$$(if $$(filter 92,$$(i)),$$$$(c_backslash),$$(if $$(filter 93,$$(i)),],$$(if $$(filter 94,$$(i)),^,$$(if $$(filter 95,$$(i)),_,$$(if $$(filter 96,$$(i)),`,$$(if $$(filter 97,$$(i)),a,$$(if $$(filter 98,$$(i)),b,$$(if $$(filter 99,$$(i)),c,$$(if $$(filter 100,$$(i)),d,$$(if $$(filter 101,$$(i)),e,$$(if $$(filter 102,$$(i)),f,$$(if $$(filter 103,$$(i)),g,$$(if $$(filter 104,$$(i)),h,$$(if $$(filter 105,$$(i)),i,$$(if $$(filter 106,$$(i)),j,$$(if $$(filter 107,$$(i)),k,$$(if $$(filter 108,$$(i)),l,$$(if $$(filter 109,$$(i)),m,$$(if $$(filter 110,$$(i)),n,$$(if $$(filter 111,$$(i)),o,$$(if $$(filter 112,$$(i)),p,$$(if $$(filter 113,$$(i)),q,$$(if $$(filter 114,$$(i)),r,$$(if $$(filter 115,$$(i)),s,$$(if $$(filter 116,$$(i)),t,$$(if $$(filter 117,$$(i)),u,$$(if $$(filter 118,$$(i)),v,$$(if $$(filter 119,$$(i)),w,$$(if $$(filter 120,$$(i)),x,$$(if $$(filter 121,$$(i)),y,$$(if $$(filter 122,$$(i)),z,$$(if $$(filter 123,$$(i)),{,$$(if $$(filter 124,$$(i)),|,$$(if $$(filter 125,$$(i)),},$$(if $$(filter 126,$$(i)),~,$$(if $$(IGNORE_UNREPRESENTABLE_CHARACTERS),,$$(error Unrepresentable character was found: $$(i)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))) \
	)
endif
 print_stack :=
endef


define flush
 ifneq '$(DEBUG)' ''
  $$(info $$(print_stack))
 endif
 $$(eval $$(call mkres))
 $$(info $$(RES))
endef



# Executes an intruction of index idx in PROG_SEP
define execute_inst
 INST := $$(strip $$(word $$(idx), $$(PROG_SEP)))
 ifneq '$(DEBUG)' ''
  $$(warning INST: $$(INST))
 endif
 garbage := \
	$$(if $$(strip $$(filter-out 0, $$(n_of_]s_to_skip))), \
		$$(if $$(strip $$(filter [, $$(INST))), \
			$$(eval n_of_]s_to_skip := $$(call plus_1, $$(n_of_]s_to_skip))), \
			$$(if $$(strip $$(filter ], $$(INST))), \
				$$(eval n_of_]s_to_skip := $$(call minus_1, $$(n_of_]s_to_skip))), \
			), \
		), \
		$$(if $$(strip $$(filter >, $$(INST))), \
			$$(eval $$(call do_>)), \
			$$(if $$(strip $$(filter <, $$(INST))), \
				$$(eval $$(call do_<)), \
				$$(if $$(strip $$(filter +, $$(INST))), \
					$$(eval $$(call do_+)), \
					$$(if $$(strip $$(filter -, $$(INST))), \
						$$(eval $$(call do_-)), \
						$$(if $$(strip $$(filter ., $$(INST))), \
							$$(eval $$(call do_.)), \
							$$(if $$(strip $$(filter $$(c_comma), $$(INST))), \
								$$(eval $$(call do_comma)), \
								$$(if $$(strip $$(filter [, $$(INST))), \
									$$(eval $$(call do_[)), \
									$$(if $$(strip $$(filter ], $$(INST))), \
										$$(eval $$(call do_])), \
									) \
								) \
							) \
						) \
					) \
				) \
			) \
		) \
	)
endef


define execute
 idx_next := $$(call plus_1, $$(idx))
 ifneq '$(DEBUG)' ''
  $$(warning idx: $$(idx) $(idx_next))
 endif
 $$(eval $$(call execute_inst, $$(idx)))
 garbage := \
	$$(if $$(strip $$(filter-out $$(call plus_1, $$(words $$(PROG_SEP))), $$(idx_next))), \
		$$(eval idx := $$(idx_next)) \
		$$(eval $$(call execute)), \
	)
endef



data_head :=
data_cur := 0
data_tail :=

print_stack :=
n_of_]s_to_skip := 0
[_idxs_stack :=

idx := 1
$(eval $(call execute))

ifneq '$(DEBUG)' ''
 $(warning ------------)
 $(warning ** Data **)
 $(warning head: $(data_head))
 $(warning cur:  $(data_cur))
 $(warning tail: $(data_tail))
 $(warning ** Print **)
 $(eval $(call flush))
 $(warning ** Debug **)
 $(warning n_of_]s_to_skip: $(n_of_]s_to_skip))
 $(warning [_idxs_stack: $([_idxs_stack))
else
 ifneq '$(BUFFERING)' ''
  $(eval $(call flush))
 endif
endif



# To avoid "No targets.  Stop." message:
.PHONY: -
-:
	@:
