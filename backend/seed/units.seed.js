/**
 * Default standard industrial manufacturing units
 */
export const DEFAULT_UNITS = [
  // Count
  { code: 'PCS', name: 'Pieces', symbol: 'pcs', category: 'Count', precision: 0 },
  { code: 'NOS', name: 'Numbers', symbol: 'nos', category: 'Count', precision: 0 },
  { code: 'SET', name: 'Set', symbol: 'set', category: 'Count', precision: 0 },
  { code: 'PAIR', name: 'Pair', symbol: 'pair', category: 'Count', precision: 0 },
  { code: 'DOZEN', name: 'Dozen', symbol: 'dz', category: 'Count', precision: 0 },

  // Weight
  { code: 'KG', name: 'Kilogram', symbol: 'kg', category: 'Weight', precision: 2 },
  { code: 'G', name: 'Gram', symbol: 'g', category: 'Weight', precision: 2 },
  { code: 'TON', name: 'Metric Ton', symbol: 't', category: 'Weight', precision: 3 },
  { code: 'MG', name: 'Milligram', symbol: 'mg', category: 'Weight', precision: 1 },
  { code: 'LB', name: 'Pound', symbol: 'lb', category: 'Weight', precision: 2 },

  // Volume
  { code: 'L', name: 'Liter', symbol: 'L', category: 'Volume', precision: 2 },
  { code: 'ML', name: 'Milliliter', symbol: 'mL', category: 'Volume', precision: 0 },
  { code: 'KL', name: 'Kiloliter', symbol: 'kL', category: 'Volume', precision: 3 },
  { code: 'GAL', name: 'Gallon', symbol: 'gal', category: 'Volume', precision: 2 },

  // Length
  { code: 'M', name: 'Meter', symbol: 'm', category: 'Length', precision: 2 },
  { code: 'MM', name: 'Millimeter', symbol: 'mm', category: 'Length', precision: 1 },
  { code: 'CM', name: 'Centimeter', symbol: 'cm', category: 'Length', precision: 1 },
  { code: 'INCH', name: 'Inch', symbol: 'in', category: 'Length', precision: 2 },
  { code: 'FT', name: 'Feet', symbol: 'ft', category: 'Length', precision: 2 },
  { code: 'YD', name: 'Yard', symbol: 'yd', category: 'Length', precision: 2 },

  // Area
  { code: 'SQM', name: 'Square Meter', symbol: 'm²', category: 'Area', precision: 2 },
  { code: 'SQFT', name: 'Square Feet', symbol: 'sq ft', category: 'Area', precision: 2 },

  // Packaging
  { code: 'BOX', name: 'Box', symbol: 'box', category: 'Packaging', precision: 0 },
  { code: 'ROLL', name: 'Roll', symbol: 'roll', category: 'Packaging', precision: 0 },
  { code: 'BAG', name: 'Bag', symbol: 'bag', category: 'Packaging', precision: 0 },
  { code: 'BUNDLE', name: 'Bundle', symbol: 'bdl', category: 'Packaging', precision: 0 },
  { code: 'DRUM', name: 'Drum', symbol: 'drum', category: 'Packaging', precision: 0 },
  { code: 'CAN', name: 'Can', symbol: 'can', category: 'Packaging', precision: 0 },
];
