# UI Reference Implementation

## Source availability

The strict UI specification was received as text. The referenced three cosmetics screenshots were not present in its attachment directory. Two unrelated images found in other attachment directories were explicitly excluded. Therefore this implementation follows the written geometry and color specification and does not claim pixel-perfect comparison.

## Implemented tokens

- Background `#FFFFFF`
- Primary pink `#C12391`
- Cashback pink `#E60093`
- Soft pink `#F8EAF1`
- Rose surface `#E8BCD1`
- Input `#F3F3F3`
- Secondary surface `#F7F7F8`
- Primary text `#151515`
- Secondary text `#898989`
- Border `#E6E6E6`

Typography declares Manrope with Inter, SF Pro Display and Roboto fallbacks. A licensed Manrope font binary has not been supplied, so an exact font match is not claimed.

## Reusable Flutter components

- Floating capsule bottom navigation with selected pink state and cart badge support.
- Responsive product card with contained image, favorite, discount/cashback labels and quantity controls.
- Asymmetric-grid-ready category card with configurable height and contained bottom imagery.
- +998 phone authentication form with validation, terms checkbox, safe-area action and an injected real-submit callback.
- Shared empty and error states.

The authentication page is not connected to navigation because no OTP backend contract exists. Product/category components are not populated with permanent fixtures because the catalog API is missing.

## Verification

- Flutter static analysis and unit tests pass.
- Flutter Web release build succeeds.
- Headless Chrome loaded the Flutter release bundle, but the available headless macOS renderer produced a blank captured frame. This is recorded as a visual-verification limitation, not a successful design comparison.

