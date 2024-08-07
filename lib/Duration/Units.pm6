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
my %abrv = (
  SECOND  => 'sec',
  MINUTE  => 'min',
  HOUR    => 'hrs',
  DAY     => 'days',
  WEEK    => 'wks',
  MONTH   => 'mon',
  YEAR    => 'yrs',
  DECADE  => 'dec',
  CENTURY => 'cen'
);

role Duration::Units {

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

  method get-max-unit (
    :seconds(:$second)             = False,
    :minutes(:$minute)             = False,
    :hours(:$hour)                 = False,
    :days(:$day)                   = False,
    :weeks(:$week)                 = False,
    :months(:$month)               = False,
    :years(:$year)                 = False,
    :decades(:$decade)             = False,
    :century(:$centuries)          = True
  ) {
    do {
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
  }

  multi method components (
    :$quick                        = False,

    :seconds(:$second)             = False,
    :minutes(:$minute)             = False,
    :hours(:$hour)                 = False,
    :days(:$day)                   = False,
    :weeks(:$week)                 = False,
    :months(:$month)               = False,
    :years(:$year)                 = False,
    :decades(:$decade)             = False,
    :century(:$centuries)          = True
  ) {
    samewith(
      self.get-max-unit(
        :$second,
        :$minute,
        :$hour,
        :$day,
        :$week,
        :$month,
        :$year,
        :$decade,
        :$centuries
      ),
      :$quick
    );
  }
  multi method components ( $max-unit = CENTURY, :$quick = False ) {
    my $t = self;
    do gather for self.component-order.kv -> $k, &m {
      if &m($t).Int -> $v {
        next if $max-unit.Int < &m.date-component-value.Int;
        take [ $v, &m.date-component-value ];
        last if $quick;
        $t = ( $t - $v * self.inv-component-order[$k](self) )
          but Duration::Units;
        last if $t <= 0;
      }
    }
  }

  multi method ago (
    :fuzzy(:$quick)             = False,
    :sec(:seconds(:$second))    = False,
    :min(:minutes(:$minute))    = False,
    :hr(:hours(:$hour))         = False,
    :days(:$day)                = False,
    :wk(:wks(:weeks(:$week)))   = False,
    :mon(:months(:$month))      = False,
    :yr(:yrs(:years(:$year)))   = False,
    :dec(:decades(:$decade))    = False,
    :cen(:century(:$centuries)) = False,
    :$separator                 = ', ',
    :$unit-separator            = ' ',
    :abbr(:$abbreviated)        = False,
    :init(:$initial)            = False,

    :max_unit(:max_units(:max-units(:$max-unit))) is copy,
  ) {
    my $rep := $abbreviated ?? %names !! %abrv;
    $max-unit //= self.get-max-unit(
      :$second,
      :$minute,
      :$hour,
      :$day,
      :$week,
      :$month,
      :$year,
      :$decade,
      :$centuries
    );

    self.components(:$quick, :$max-unit).map({
      my $u = .[1].Str;

      my $w = $abbreviated ?? $rep{$u} !! $u.lc;
      if $initial {
        $w = do given $max-unit {
          when    MONTH  { 'mn'  }
          when    DECADE { 'dec' }
          default        { $w.comb.head }
        }
      } elsif .[0] > 1 {
        my $ies = False;
        $ies = True if $w.ends-with('y') && $w ne 'day';
        $w .= chop if $ies;
        $w ~= $ies ?? 'ies' !! 's'
      }

      # cw: What to do about min-vs-mon or day-vs-dec
      "{ .[0] }{ $unit-separator }{ $w }"
    }).join($separator);
  }

  method add ($b) {
    (self + $b) but Duration::Units;
  }

  method subtract ($b) {
    (self - $b) but Duration::Units;
  }

  method factor ($f) {
    (self * $f) but Duration::Units;
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
  Duration.new($a) but Duration::Units;
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
  Duration.new(postfix:<seconds>($a) * 60) but Duration::Units;
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
  Duration.new(postfix:<minutes>($a) * 60) but Duration::Units;
}

multi sub postfix:<d> ($a) is export {
  postfix:<days>($a);
}
multi sub postfix:<day> ($a) is export {
  postfix:<days>($a);
}
multi sub postfix:<days> ($a) is export {
  Duration.new(postfix:<hours>($a) * 24) but Duration::Units;
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
  Duration.new(postfix:<days>($a) * 7) but Duration::Units;
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
  Duration.new(postfix:<days>($a) * 365.24) but Duration::Units;
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
  Duration.new( &postfix:<years>($a) / 12 ) but Duration::Units;
}

multi sub infix:<-> (DateTime $a, DateTime $b) is export {
  # cw: We have to push $b back one second, or it will look off by a second!
  callwith( $a, $b.earlier( :1second ) ) but Duration::Units;
}
