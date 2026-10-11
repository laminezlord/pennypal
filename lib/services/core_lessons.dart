/// Built-in financial-literacy lessons covering the SRS learning topics
/// (budgeting, saving, income, necessary expenses and optional expenses).
///
/// They ship with the app so the Learn section always has content, even
/// before an administrator publishes extra lessons to Firestore or while the
/// device is offline. Admin-published lessons are shown alongside these.
const coreLessons = <Map<String, dynamic>>[
  {
    'id': 'core_budgeting',
    'title': 'Budgeting 101: give every naira a job',
    'topic': 'Budgeting',
    'difficulty': 'Beginner',
    'body': 'A budget is a plan for your money before you spend it.\n\n'
        '1. Write down what you expect to receive this month (allowance, stipend, part-time pay).\n'
        '2. List your fixed costs first: rent or hostel fees, transport, data and study materials.\n'
        '3. Set a limit for flexible spending such as food out, shopping and entertainment.\n'
        '4. Put something aside for savings, even if it is small.\n\n'
        'Example: with ₦60,000 a month you might plan ₦25,000 for food, ₦10,000 for transport, '
        '₦8,000 for data and books, ₦7,000 for fun and ₦10,000 for savings.\n\n'
        'In PennyPal: open Budget, set a monthly limit, then add category limits for the areas where you overspend most.',
  },
  {
    'id': 'core_saving',
    'title': 'Saving that actually sticks',
    'topic': 'Saving',
    'difficulty': 'Beginner',
    'body': 'Saving works best when it is automatic and has a purpose.\n\n'
        '• Pick a clear goal (a laptop, an emergency fund, next semester\'s fees).\n'
        '• Decide the target amount and a realistic date.\n'
        '• Divide the remaining amount by the months left to get your monthly contribution.\n'
        '• Save at the start of the month, not with whatever is left at the end.\n\n'
        'Example: a ₦150,000 laptop in 6 months needs ₦25,000 per month.\n\n'
        'In PennyPal: create a goal in Goals and record each contribution to watch your progress and milestones.',
  },
  {
    'id': 'core_income',
    'title': 'Understanding your income',
    'topic': 'Income',
    'difficulty': 'Beginner',
    'body': 'Income is any money you receive: allowance, scholarship, stipend, gifts or wages from part-time work.\n\n'
        '• Regular income arrives on a predictable schedule, so you can plan around it.\n'
        '• Irregular income (gigs, gifts) is less predictable, so budget with your lowest typical month.\n'
        '• When extra money arrives, decide its job straight away: savings, a goal or a planned purchase.\n\n'
        'In PennyPal: record each income entry with its source so your balance and reports stay accurate.',
  },
  {
    'id': 'core_needs',
    'title': 'Necessary expenses (needs)',
    'topic': 'Necessary expenses',
    'difficulty': 'Beginner',
    'body': 'Needs are costs you must cover to live and study: basic food, accommodation, transport to class, '
        'required books and essential bills.\n\n'
        'Tips:\n'
        '• Pay for needs first when money arrives.\n'
        '• Look for cheaper versions of the same need: cooking instead of eating out, shared transport, used textbooks.\n'
        '• Track needs in their own categories (Food, Transport, Education, Bills) so you know your minimum monthly cost.',
  },
  {
    'id': 'core_wants',
    'title': 'Optional expenses (wants)',
    'topic': 'Optional expenses',
    'difficulty': 'Beginner',
    'body': 'Wants make life more enjoyable but are not essential: takeaway meals, new clothes, streaming subscriptions, outings and gadgets.\n\n'
        'Wants are not bad. The goal is to choose them on purpose.\n'
        '• Set a fixed monthly amount for wants.\n'
        '• Use a 24-hour rule before unplanned purchases.\n'
        '• Review subscriptions every month and cancel the ones you rarely use.\n\n'
        'Quick check: "Would I still need this if nobody could see it?"',
  },
  {
    'id': 'core_requirements',
    'title': 'Planning for upcoming requirements',
    'topic': 'Requirements',
    'difficulty': 'Intermediate',
    'body': 'Some costs are certain but not monthly: exam fees, project materials, hostel renewal, a new phone screen.\n\n'
        '• List the known costs coming in the next 6 to 12 months.\n'
        '• Turn each one into a savings goal with a target date.\n'
        '• Keep a small emergency fund (even one month of needs) for the surprises you cannot list.\n\n'
        'Planning early turns a stressful bill into a small, steady monthly contribution.',
  },
];
