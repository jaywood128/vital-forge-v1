# frozen_string_literal: true

module Epley1Rm
  def epley_1rm(weight, reps)
    return weight.to_f if reps == 1
    weight.to_f * (1 + reps.to_f / 30)
  end
end
