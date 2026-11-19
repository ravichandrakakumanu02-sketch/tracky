import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracky/main.dart';
import 'package:tracky/models/exercise_model.dart';
import 'package:tracky/models/workout_model.dart';
import 'package:tracky/screens/home_screen.dart';
import 'package:tracky/services/workout_service.dart';

void main() {
  setUp(() async {
    // Reset service state before each test using local repository
    WorkoutService().setRepository(LocalWorkoutRepository(seedInitialData: false));
    await WorkoutService().clearAll();
  });

  testWidgets('Tracky launches and renders header, minimal calendar, summary, and empty state',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TrackyApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // Verify App Header
    expect(find.text('Tracky'), findsOneWidget);
    expect(find.text('Welcome back! 💪'), findsOneWidget);

    // Verify Summary Cards labels
    expect(find.text('Total Days'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);

    // Verify Minimal Calendar Widget is displayed
    expect(find.text('Workout Calendar'), findsOneWidget);

    // Verify Empty State required text
    expect(
      find.text('Start tracking your fitness journey!'),
      findsOneWidget,
    );
    expect(
      find.text('No workouts logged yet.'),
      findsOneWidget,
    );

    // Verify Floating Action Button exists
    expect(find.text('Add Today\'s Workout'), findsOneWidget);
  });

  testWidgets('Workouts render in history, calendar highlights day, and popup opens on tap',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final testWorkout = Workout(
      id: 'test_workout_1',
      date: now,
      bodyWeightKg: 78.5,
      note: 'Felt great on deadlifts',
      exercises: const [
        Exercise(
          id: 'test_ex_1',
          name: 'Deadlift',
          sets: 4,
          reps: 8,
          weightKg: 140.0,
        ),
      ],
    );

    await WorkoutService().addWorkout(testWorkout);

    await tester.pumpWidget(const TrackyApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // Verify stats
    expect(find.text('1'), findsWidgets);
    expect(find.text('78.5'), findsOneWidget); // Latest weight

    // Verify exercise card content in history list
    expect(find.text('Deadlift'), findsOneWidget);
    expect(find.text('4 × 8'), findsOneWidget);
    expect(find.text('140 kg'), findsOneWidget);
    expect(find.text('78.5 kg'), findsOneWidget);

    // Tap the workout card to pop up the session modal
    await tester.tap(find.text('Deadlift'));
    await tester.pumpAndSettle();

    // Verify pop-up modal content is displayed clearly
    expect(find.text('Exercise Breakdown'), findsOneWidget);
    expect(find.text('Felt great on deadlifts'), findsOneWidget);
    expect(find.text('Total Volume'), findsOneWidget);

    // Close the pop-up modal
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    // Verify back on home screen
    expect(find.text('Workout History'), findsOneWidget);
  });

  testWidgets('Navigate to Add Workout Screen and back', (WidgetTester tester) async {
    await tester.pumpWidget(const TrackyApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // Tap Floating Action Button
    await tester.tap(find.text('Add Today\'s Workout'));
    await tester.pumpAndSettle();

    // Verify Add Workout Screen is visible
    expect(find.text('Today\'s Workout'), findsOneWidget);
    expect(find.text('Today\'s Body Weight *'), findsOneWidget);
    expect(find.text('Save Workout'), findsOneWidget);
    expect(find.text('Add Another Exercise'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // Verify returned to Home Screen
    expect(find.text('Tracky'), findsOneWidget);
  });

  testWidgets('Add multiple exercises and save workout flow updates home screen and calendar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TrackyApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // Navigate to Add Workout Screen
    await tester.tap(find.text('Add Today\'s Workout'));
    await tester.pumpAndSettle();

    // Fill in body weight
    final weightField = find.widgetWithText(TextFormField, 'Today\'s Body Weight *');
    await tester.enterText(weightField, '72.5');

    // Fill in first exercise name
    final exerciseNameField = find.widgetWithText(TextFormField, 'Exercise Name *');
    await tester.enterText(exerciseNameField, 'Overhead Press');

    // Add another exercise
    await tester.tap(find.text('Add Another Exercise'));
    await tester.pumpAndSettle();

    // Now there should be Exercise #1 and Exercise #2
    expect(find.text('Exercise #1'), findsOneWidget);
    expect(find.text('Exercise #2'), findsOneWidget);

    // Fill in second exercise name
    final allExerciseFields = find.widgetWithText(TextFormField, 'Exercise Name *');
    await tester.enterText(allExerciseFields.at(1), 'Dumbbell Lateral Raise');

    // Tap Save Workout button
    await tester.tap(find.text('Save Workout'));
    await tester.pumpAndSettle();

    // Should return to Home Screen
    expect(find.text('Tracky'), findsOneWidget);

    // Verify newly added workout is present in Workout History
    expect(find.text('Overhead Press'), findsOneWidget);
    expect(find.text('Dumbbell Lateral Raise'), findsOneWidget);
    expect(find.text('72.5 kg'), findsOneWidget);

    // Tap to verify pop-up modal works on newly saved workout
    await tester.tap(find.text('Overhead Press'));
    await tester.pumpAndSettle();

    expect(find.text('Exercise Breakdown'), findsOneWidget);
    expect(find.text('2 ex'), findsOneWidget);
  });
}
