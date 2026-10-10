#include "Interval.h"

#include <cassert>
#include <iostream>

// Checks interval arithmetic results and the conservative overflow fallback.
int main() {
  // A temperature read in [-40, 85] added to itself gives [-80, 170].
  const Interval temperature = Interval::closed(-40, 85);
  const Interval doubled = Interval::add(temperature, temperature, 32);
  assert(doubled.isKnown() && doubled.min() == -80 && doubled.max() == 170);

  // Subtraction uses the smallest left minus largest right endpoint.
  const Interval difference =
      Interval::sub(Interval::closed(5, 10), Interval::closed(2, 3), 32);
  assert(difference.isKnown() && difference.min() == 2 && difference.max() == 8);

  // Multiplication checks all four pairs because either sign can change the bounds.
  const Interval product =
      Interval::mul(Interval::closed(-3, 4), Interval::closed(2, 5), 32);
  assert(product.isKnown() && product.min() == -15 && product.max() == 20);

  // A possible signed 8-bit overflow is unknown instead of an unsound range.
  const Interval overflow =
      Interval::add(Interval::closed(100, 120), Interval::closed(20, 20), 8);
  assert(!overflow.isKnown());

  std::cout << "Interval tests passed\n";
  return 0;
}
