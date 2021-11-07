use v6;

use MONKEY-TYPING;

augment class Duration {

  method minutes   { self         / 60     }
  method hours     { self.minutes / 60     }
  method days      { self.hour    / 24     }
  method weeks     { self.days    / 7      }
  method years     { self.days    / 365.75 }
  method decades   { self.years   / 10     }
  method centuries { self.years   / 100    }

  method ago {
    my enum TimeUnit <SECOND MINUTE HOUR DAY WEEK YEAR DECADE CENTURY>;

    my $almost = True;
    my $time-unit;
    my $time-unit = do {

      when ($time-val = self.centuries) >= 0.90 {
        $almost = False if self.centuries >= 1;
        CENTURY
      }

      when ($time-val = self.decades) >= 0.90 {
        $almost = False if self.decades >= 1;
        DECADE
      }

      when ($time-val = self.years) >= 0.90 {
        $almost = False if self.years >= 1;
        YEAR
      }

      when ($time-val = self.months) >= 0.90 {
        $almost = False if self.months >= 1;
        MONTH
      }

      when ($time-val = self.weeks) >= 0.90 {
        $almost = False if self.weeks >= 1;
        WEEK;
      }

      when ($time-val = self.days) >= 0.90 {
        $almost = False if self.days >= 1;
        DAY;
      }

      when ($time-val = self.hours) >= 0.9 {
        $almost = False if self.hours >= 1;
        HOUR;
      }

      when ($time-val = self.minutes) >= 0.9 {
        $almost = False if self.minutes >= 1;
        MINUTE
      }

      default {
        $time-val = self;
        SECOND;
      }

      "{ $almost ?? 'almost ' !! '' }{ $time-val } { $time-unit.Str.lc }{
         $time-val != 1 ?? 's' !! '' } ago"
    }
}
