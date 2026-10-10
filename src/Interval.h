#ifndef SENSOR_RANGE_INTERVAL_H
#define SENSOR_RANGE_INTERVAL_H

#include <algorithm>
#include <array>
#include <cstdint>
#include <limits>

// Represents either a known inclusive signed-integer range or an unknown range.
class Interval {
public:
  // Creates an unknown interval when no safe range can be proven.
  static Interval unknown() { return Interval(false, 0, 0); }

  // Creates a known inclusive range, or unknown when the endpoints are invalid.
  static Interval closed(int64_t min, int64_t max) {
    return min <= max ? Interval(true, min, max) : unknown();
  }

  // Reports whether this interval has proven lower and upper bounds.
  bool isKnown() const { return m_known; }

  // Returns the inclusive lower bound; callers must first check isKnown().
  int64_t min() const { return m_min; }

  // Returns the inclusive upper bound; callers must first check isKnown().
  int64_t max() const { return m_max; }

  // Adds two ranges and returns unknown when a result could overflow bitWidth.
  static Interval add(const Interval &left, const Interval &right,
                      unsigned bitWidth) {
    if (!left.isKnown() || !right.isKnown())
      return unknown();
    return fromWide(static_cast<__int128>(left.m_min) + right.m_min,
                    static_cast<__int128>(left.m_max) + right.m_max, bitWidth);
  }

  // Subtracts two ranges and returns unknown when a result could overflow bitWidth.
  static Interval sub(const Interval &left, const Interval &right,
                      unsigned bitWidth) {
    if (!left.isKnown() || !right.isKnown())
      return unknown();
    return fromWide(static_cast<__int128>(left.m_min) - right.m_max,
                    static_cast<__int128>(left.m_max) - right.m_min, bitWidth);
  }

  // Multiplies two ranges after checking every endpoint combination for overflow.
  static Interval mul(const Interval &left, const Interval &right,
                      unsigned bitWidth) {
    if (!left.isKnown() || !right.isKnown())
      return unknown();

    // A product can reach its extrema at any pair of input interval endpoints.
    const std::array<__int128, 4> products = {
        static_cast<__int128>(left.m_min) * right.m_min,
        static_cast<__int128>(left.m_min) * right.m_max,
        static_cast<__int128>(left.m_max) * right.m_min,
        static_cast<__int128>(left.m_max) * right.m_max};
    const auto bounds = std::minmax_element(products.begin(), products.end());
    return fromWide(*bounds.first, *bounds.second, bitWidth);
  }

  // Joins two ranges, as needed when control-flow paths merge at a phi node.
  static Interval unite(const Interval &left, const Interval &right) {
    if (!left.isKnown() || !right.isKnown())
      return unknown();
    return closed(std::min(left.m_min, right.m_min),
                  std::max(left.m_max, right.m_max));
  }

  // Sign-extends a range when its endpoints fit the source integer type.
  static Interval sext(const Interval &source, unsigned sourceWidth,
                       unsigned destinationWidth) {
    if (!source.isKnown() || destinationWidth <= sourceWidth ||
        !fitsSigned(source, sourceWidth))
      return unknown();
    return closed(source.m_min, source.m_max);
  }

  // Zero-extends a non-negative range; negative source values are ambiguous.
  static Interval zext(const Interval &source, unsigned sourceWidth,
                       unsigned destinationWidth) {
    if (!source.isKnown() || source.m_min < 0 ||
        destinationWidth <= sourceWidth || !fitsSigned(source, sourceWidth))
      return unknown();
    return closed(source.m_min, source.m_max);
  }

  // Truncates only when every possible value already fits the destination type.
  static Interval trunc(const Interval &source, unsigned destinationWidth) {
    if (!source.isKnown() || !fitsSigned(source, destinationWidth))
      return unknown();
    return closed(source.m_min, source.m_max);
  }

private:
  // Initializes a range using the supplied known-state and endpoints.
  Interval(bool known, int64_t min, int64_t max)
      : m_known(known), m_min(min), m_max(max) {}

  // Converts wide temporary arithmetic to int64_t only when it fits the IR type.
  static Interval fromWide(__int128 min, __int128 max, unsigned bitWidth) {
    if (bitWidth == 0 || bitWidth > 64)
      return unknown();

    // Compute the signed range representable by an LLVM integer of bitWidth bits.
    const __int128 typeMin = bitWidth == 64
                                 ? std::numeric_limits<int64_t>::min()
                                 : -((__int128)1 << (bitWidth - 1));
    const __int128 typeMax = bitWidth == 64
                                 ? std::numeric_limits<int64_t>::max()
                                 : (((__int128)1 << (bitWidth - 1)) - 1);
    if (min < typeMin || max > typeMax)
      return unknown();
    return closed(static_cast<int64_t>(min), static_cast<int64_t>(max));
  }

  // Checks whether every endpoint is representable as a signed bitWidth integer.
  static bool fitsSigned(const Interval &interval, unsigned bitWidth) {
    return fromWide(interval.m_min, interval.m_max, bitWidth).isKnown();
  }

  bool m_known;
  int64_t m_min;
  int64_t m_max;
};

#endif
