use v6;

use MONKEY-TYPING;

my enum TimeUnit is export <
  SECOND
  MINUTE
  HOUR
  DAY
  WEEK
  MONTH
  YEAR
  DECADE
  CENTURY
>;

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
  YEAR    => 'years',
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

  method secs  { self.seconds   }
  method mins  { self.minutes   }
  method hrs   { self.hours     }
  method wks   { self.weeks     }
  method mnths { self.months    }
  method yrs   { self.years     }
  method decs  { self.decades   }
  method cens  { self.centuries }

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

  method components ( :$max-unit = CENTURY, :$quick = False ) {
    my $t = self;
    do gather for self.component-order.kv -> $k, &m {
      if &m($t).Int -> $v {
        next if $max-unit.Int < &m.date-component-value.Int;
        take [ $v, &m.date-component-value ];
        last if $quick;
        $t -= $v * self.inv-component-order[$k](self);
        last if $t <= 0;
      }
    }
  }

  multi method ago (
    :$max-unit            is copy,
    :fuzzy(:$quick)                = False,
    :seconds(:$second)             = False,
    :minutes(:$minute)             = False,
    :hours(:$hour)                 = False,
    :days(:$day)                   = False,
    :weeks(:$week)                 = False,
    :months(:$month)               = False,
    :years(:$year)                 = False,
    :decades(:$decade)             = False,
    :century(:$centuries)          = True,
    :$separator                    = ', '
  ) {
    $max-unit //= do {
       when $second.so    { SECOND  }
       when $minute.so    { MINUTE  }
       when $hour.so      { HOUR    }
       when $day.so       { DAY     }
       when $week.so      { WEEK    }
       when $month.so     { MONTH   }
       when $year.so      { YEAR    }
       when $decade.so    { DECADE  }
       when $centuries.so { CENTURY }
    }

    self.components(:$quick, :$max-unit).map({
      my $u = .[1].Str;

      "{ .[0] } { .[0] == 1 ?? $u.lc !! %names{$u} }"
    }).join($separator);
  }

}

multi sub postfix:<s> ($a) is export {
  postfix:<seconds>($a);
}
multi sub postfix:<sec> ($a) is export {
  postfix:<seconds>($a);
}
multi sub postfix:<secs> ($a) is export {
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
multi sub postfix:<min> ($a) is export {
  postfix:<minutes>($a);
}
multi sub postfix:<mins> ($a) is export {
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
multi sub postfix:<hr> ($a) is export {
  postfix:<hours>($a);
}
multi sub postfix:<hrs> ($a) is export {
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
multi sub postfix:<wk> ($a) is export {
  postfix:<weeks>($a);
}
multi sub postfix:<wks> ($a) is export {
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
multi sub postfix:<yr> ($a) is export {
  postfix:<years>($a);
}
multi sub postfix:<yrs> ($a) is export {
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
multi sub postfix:<mnth> ($a) is export {
  postfix:<months>($a);
}
multi sub postfix:<mnths> ($a) is export {
  postfix:<months>($a);
}
multi sub postfix:<month> ($a) is export {
  postfix:<months>($a);
}
multi sub postfix:<months> ($a) is export {
  Duration.new( &postfix:<years>($a) / 12 );
}
