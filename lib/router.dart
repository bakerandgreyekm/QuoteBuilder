import 'package:go_router/go_router.dart';
import 'screens/projects_list_screen.dart';
import 'screens/project_detail_screen.dart';
import 'screens/system_detail_screen.dart';
import 'screens/add_line_item_screen.dart';
import 'screens/quote_summary_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ProjectsListScreen(),
    ),
    GoRoute(
      path: '/project/:id',
      builder: (context, state) => ProjectDetailScreen(
        projectId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/project/:id/system/:systemType',
      builder: (context, state) => SystemDetailScreen(
        projectId: state.pathParameters['id']!,
        systemType: state.pathParameters['systemType']!,
      ),
    ),
    GoRoute(
      path: '/project/:id/system/:systemType/add-item',
      builder: (context, state) => AddLineItemScreen(
        projectId: state.pathParameters['id']!,
        systemType: state.pathParameters['systemType']!,
      ),
    ),
    GoRoute(
      path: '/project/:id/quote',
      builder: (context, state) => QuoteSummaryScreen(
        projectId: state.pathParameters['id']!,
      ),
    ),
  ],
);
