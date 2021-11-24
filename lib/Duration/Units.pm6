use v6;

use MONKEY-TYPING;

my enum TimeUnit <SECOND MINUTE HOUR DAY WEEK MONTH YEAR DECADE CENTURY>;

role DateComponent[\T] {
  method date-component-value { T }
}
role InverseDateComponent[\T] {
  method date-component-value { T }
}

multi sub trait_mod:<is> (Method $m, :$date-component!) {
  $m does DateComponent[$date-component];
}
multi sub trait_mod:<is> (Method $m, :$inv-date-component!) {
  $m does InverseDateComponent[$inv-date-component];
}

my %names = (
  SECOND  => 'seconds',
  MINUTE  => 'minutes',
  HOUR    => 'hours',
  DAY     => 'days',
  WEEK    => 'weeks',
  MONTH   => 'months',
  DECADE  => 'decades',
  CENTURY => 'centuries'
);

augment class Duration {

  method seconds       is date-component(SECOND)       { self                      }
  method minutes       is date-component(MINUTE)       { self         / 60         }
  method hours         is date-component(HOUR)         { self.minutes / 60         }
  method days          is date-component(DAY)          { self.hours   / 24         }
  method weeks         is date-component(WEEK)         { self.days    / 7          }
  method years         is date-component(YEAR)         { self.days    / 365.25     }
  method months        is date-component(MONTH)        { self.years   * 12         }
  method decades       is date-component(DECADE)       { self.years   / 10         }
  method centuries     is date-component(CENTURY)      { self.years   / 100        }

  method inv-seconds   is inv-date-component(SECOND)   { 1                         }
  method inv-minutes   is inv-date-component(MINUTE)   { self.inv-seconds * 60     }
  method inv-hours     is inv-date-component(HOUR)     { self.inv-minutes * 60     }
  method inv-days      is inv-date-component(DAY)      { self.inv-hours   * 24     }
  method inv-weeks     is inv-date-component(WEEK)     { self.inv-days    * 7      }
  method inv-years     is inv-date-component(YEAR)     { self.inv-days    * 365.25 }
  method inv-months    is inv-date-component(MONTH)    { self.inv-years   / 12     }
  method inv-decades   is inv-date-component(DECADE)   { self.inv-years   * 10     }
  method inv-centuries is inv-date-component(CENTURY)  { self.inv-years   * 100    }

  method component-order {
    state @co = ::?CLASS.^methods.grep( * ~~ DateComponent )
                                 .sort( - *.date-component-value );
    @co;
  }

  method inv-component-order {
    state @co = ::?CLASS.^methods.grep( * ~~ InverseDateComponent )
                                 .sort( - *.date-component-value );
    @co;
  }

  method components {
    my @components;
    my $t = self;
    for self.component-order.kv -> $k, &m {
      my $v = &m($t).Int;

      if $v > 0 {
        my $mk = &m.date-component-value;
        @components.push: [ $v, $mk ];

        my $im = self.inv-component-order[$k];
        $t -= $v * $im(self);
        last if $t <= 0;
      }
    }
    @components;
  }

  multi method ago {
    self.components.map({
      my $u = .[1].Str;

      "{ .[0] } { .[0] == 1 ?? $u !! %names{$u} }"
    }).join(' ');
  }
  multi method ago (:$fuzzy!) {
    my $almost = True;
    my $time-val;
    my $time-unit = do {

      when ($time-val = self.centuries) >= 0.9 { CENTURY }
      when ($time-val = self.decades)   >= 0.9 { DECADE  }
      when ($time-val = self.years)     >= 0.9 { YEAR    }
      when ($time-val = self.months)    >= 0.9 { MONTH   }
      when ($time-val = self.weeks)     >= 0.9 { WEEK    }
      when ($time-val = self.days)      >= 0.9 { DAY     }
      when ($time-val = self.hours)     >= 0.9 { HOUR    }
      when ($time-val = self.minutes)   >= 0.9 { MINUTE  }

      default {
        $time-val = self;
        SECOND;
      }
    }

    $almost = False if $time-val >= 1 && $time-unit != SECOND;

    my $tu = $time-unit.Str;
    "{ $almost ?? 'almost' !! '' }{ $time-val } {
        $time-val != 1 ?? $tu !! %names{$tu} }"
  }

}

multi sub postfix:<s> ($a) is export {
  postfix:<seconds>($a);
}
multi sub postfix:<second> ($a) is export {
  postfix:<seconds>($a);
}
multi sub postfix:<seconds> ($a) is export {
  Duration.new($a);
}

multi sub postfix:<m> ($a) is export {
  postfix:<minutes>($a);
}
multi sub postfix:<minute> ($a) is export {
  postfix:<minutes>($a);
}
multi sub postfix:<minutes> ($a) is export {
  Duration.new(postfix:<seconds>($a) * 60);
}

multi sub postfix:<h> ($a) is export {
  postfix:<hours>($a);
}
multi sub postfix:<hour> ($a) is export {
  postfix:<hours>($a);
}
multi sub postfix:<hours> ($a) is export {
  Duration.new(postfix:<minutes>($a) * 60)
}

multi sub postfix:<d> ($a) is export {
  postfix:<days>($a);
}
multi sub postfix:<day> ($a) is export {
  postfix:<days>($a);
}
multi sub postfix:<days> ($a) is export {
  Duration.new(postfix:<hours>($a) * 24);
}

multi sub postfix:<w> ($a) is export {
  postfix:<weeks>($a);
}
multi sub postfix:<week> ($a) is export {
  postfix:<weeks>($a);
}
multi sub postfix:<weeks> ($a) is export {
  Duration.new(postfix:<days>($a) * 7);
}

multi sub postfix:<y> ($a) is export {
  postfix:<years>($a);
}
multi sub postfix:<year> ($a) is export {
  postfix:<years>($a);
}
multi sub postfix:<years> ($a) is export {
  Duration.new(postfix:<days>($a) * 365.24);
}

multi sub postfix:<mon> ($a) is export {
  postfix:<months>($a);
}
multi sub postfix:<month> ($a) is export {
  postfix:<months>($a);
}
multi sub postfix:<months> ($a) is export {
  Duration.new( &postfix:<years>($a) / 12 );
}
