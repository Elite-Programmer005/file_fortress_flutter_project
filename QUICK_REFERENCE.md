# Quick Reference - FileFortress UI Components & Usage

## 🎨 Theme Constants Quick Access

```dart
// Import in any file needing theme constants
import 'package:file_fortress/core/themes/app_theme.dart';

// Spacing
SizedBox(height: AppTheme.standardSpacing)        // 16px
SizedBox(height: AppTheme.largeSpacing)           // 24px
SizedBox(height: AppTheme.extraLargeSpacing)      // 32px

// Border Radius
BorderRadius.circular(AppTheme.smallRadius)       // 12px
BorderRadius.circular(AppTheme.cardRadius)        // 16px

// Typography
Text('Heading', style: AppTheme.headlineLarge)
Text('Body', style: AppTheme.bodyLarge)
Text('Caption', style: AppTheme.bodySmall)

// Animation Duration
AnimatedContainer(duration: AppTheme.animationDuration)  // 300ms
```

## 🧩 Reusable Widgets

### 1. AnimatedButton

```dart
import 'package:file_fortress/presentation/widgets/animated_button.dart';

AnimatedButton(
  onPressed: () => _handleSubmit(),
  label: 'Submit',
  icon: Icons.done_rounded,
  isLoading: isProcessing,
)
```

### 2. AnimatedCard

```dart
import 'package:file_fortress/presentation/widgets/animated_card.dart';

AnimatedCard(
  onTap: () => Navigator.push(context, /* route */),
  child: Column(
    children: [
      // Card content
    ],
  ),
)
```

### 3. LoadingOverlay

```dart
import 'package:file_fortress/presentation/widgets/loading_overlay.dart';

LoadingOverlay(
  isLoading: isProcessing,
  message: 'Processing your request...',
  child: YourMainContent(),
)
```

### 4. AnimatedPinCircle

```dart
import 'package:file_fortress/presentation/widgets/animated_pin_circle.dart';

Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(4, (index) => 
    AnimatedPinCircle(
      filled: index < enteredPin.length,
      filledColor: colorScheme.primary,
      emptyColor: colorScheme.outlineVariant,
    ),
  ),
)
```

### 5. Entrance Animations

```dart
import 'package:file_fortress/presentation/widgets/entrance_animations.dart';

// Fade + Slide up
FadeInUp(
  delayMs: 0,
  child: MyWidget(),
)

// Fade + Scale
FadeInScale(
  duration: AppTheme.transitionDuration,
  child: MyComponent(),
)

// Slide from left
SlideInLeft(
  delayMs: 100,
  child: MyElement(),
)
```

## 🌈 Colors from Theme

```dart
final colorScheme = Theme.of(context).colorScheme;

// Primary & Surfaces
colorScheme.primary              // Main brand color
colorScheme.onPrimary           // Text on primary
colorScheme.surface             // Card/background surface
colorScheme.onSurface           // Text on surface
colorScheme.surfaceVariant      // Secondary surface
colorScheme.onSurfaceVariant    // Text on surface variant

// Status
colorScheme.error               // Error/warning color
colorScheme.outline             // Borders/dividers
colorScheme.outlineVariant      // Secondary borders

// Background
colorScheme.background          // Page background
colorScheme.onBackground        // Text on background
```

## 📝 Typography Styles

```dart
AppTheme.displayLarge       // 32px, bold - hero text
AppTheme.displayMedium      // 28px, bold - page titles
AppTheme.headlineLarge      // 24px, bold - section headers
AppTheme.headlineMedium     // 20px, semi-bold - subsections
AppTheme.titleLarge         // 16px, semi-bold - card titles
AppTheme.titleMedium        // 14px, semi-bold - labels
AppTheme.titleSmall         // 12px, semi-bold - small labels
AppTheme.bodyLarge          // 16px, regular - main body text
AppTheme.bodyMedium         // 14px, regular - secondary text
AppTheme.bodySmall          // 12px, regular - captions
```

## ⏱️ Animation Durations

```dart
AppTheme.microAnimationDuration    // 100ms - button press
AppTheme.animationDuration         // 300ms - standard transition
AppTheme.mediumAnimationDuration   // 500ms - complex animation
AppTheme.transitionDuration        // 600ms - page transition
```

## 🎬 Page Transitions

```dart
import 'package:file_fortress/presentation/widgets/page_transitions.dart';

// Slide + Fade
Navigator.push(
  context,
  SmoothPageRoute(builder: (context) => NextScreen()),
);

// Fade only
Navigator.push(
  context,
  FadePageRoute(builder: (context) => NextScreen()),
);

// Scale + Fade
Navigator.push(
  context,
  ScalePageRoute(builder: (context) => NextScreen()),
);
```

## 🎯 Common Patterns

### Form Input Field

```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Enter something',
    prefixIcon: const Icon(Icons.label_rounded),
    hintText: 'Hint text',
  ),
  validator: (value) => value?.isEmpty ?? true 
    ? 'Field required' 
    : null,
)
```

### Card with Title & Subtitle

```dart
Card(
  child: ListTile(
    leading: Icon(Icons.some_icon),
    title: Text('Title', style: AppTheme.titleMedium),
    subtitle: Text('Subtitle', style: AppTheme.bodySmall),
    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    onTap: () { /* action */ },
  ),
)
```

### Error Message

```dart
Container(
  padding: const EdgeInsets.all(AppTheme.standardSpacing),
  decoration: BoxDecoration(
    color: colorScheme.error.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
    border: Border.all(color: colorScheme.error.withOpacity(0.3)),
  ),
  child: Row(
    children: [
      Icon(Icons.error_outline, color: colorScheme.error),
      const SizedBox(width: AppTheme.mediumSpacing),
      Expanded(
        child: Text(
          'Error message',
          style: AppTheme.bodySmall.copyWith(color: colorScheme.error),
        ),
      ),
    ],
  ),
)
```

### Staggered Animation

```dart
Column(
  children: [
    FadeInUp(delayMs: 0, child: Widget1()),
    FadeInUp(delayMs: 100, child: Widget2()),
    FadeInUp(delayMs: 200, child: Widget3()),
  ],
)
```

## 🔧 Customization Tips

### Change Theme Color Globally
Edit `app_theme.dart`:
```dart
seedColor: const Color(0xFF0052D4), // Change this
```

### Adjust Animation Speed
Edit `app_theme.dart`:
```dart
static const Duration animationDuration = Duration(milliseconds: 300); // Change value
```

### Modify Spacing System
Edit `app_theme.dart`:
```dart
static const double standardSpacing = 16.0; // Adjust as needed
```

## ✅ Best Practices

1. **Always use AppTheme constants** - Never hardcode values
2. **Use colorScheme from context** - Respects light/dark mode
3. **Keep animations under 600ms** - Avoid sluggish feel
4. **Stack animations with delays** - Use `delayMs` for stagger
5. **Test on real devices** - Emulators don't reflect true performance
6. **Maintain 60 FPS** - Avoid complex widget rebuilds in animations
7. **Group related spacing** - Use consistent gaps between sections
8. **Document custom components** - Add usage examples

## 🐛 Troubleshooting

**Animation feels choppy?**
- Check if rebuild is happening inside animated widget
- Verify no heavy computations in build method
- Use `const` constructors where possible

**Colors look different in dark mode?**
- Always use `colorScheme` from context
- Test both themes during development
- Check contrast ratios for accessibility

**Text is too large/small?**
- Use AppTheme typography styles
- Don't override fontSize manually
- Respects system text scale settings

---

**Last Updated**: February 2026  
**Version**: 1.0.0
