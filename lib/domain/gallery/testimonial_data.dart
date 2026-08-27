/// Testimonial data, ported 1:1 from the React gallery's
/// `src/config/testimonials.ts`.
///
/// TODO: replace with live LinkedIn recommendations via API — carried over
/// from the TypeScript source.
///
/// The list drives the back-wall layout: each entry becomes one framed card
/// plus its own spotlight, spaced along the wall. The trailing CTA entry is a
/// blank card that opens the recommendation form rather than showing a quote,
/// so it must stay last — the camera's wall pan ends on it.
class Testimonial {
  const Testimonial({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    required this.text,
    required this.relationship,
    this.date,
    this.photoUrl,
    this.linkedinUrl,
    this.isCTA = false,
  });

  /// The blank end-of-wall card that opens the "leave a recommendation" form.
  const Testimonial.cta()
      : id = 'cta',
        name = '',
        role = '',
        company = '',
        text = '',
        relationship = '',
        date = null,
        photoUrl = null,
        linkedinUrl = null,
        isCTA = true;

  final String id;
  final String name;
  final String role;
  final String company;
  final String text;

  /// How the recommender knows Vishal — e.g. "Managed Vishal".
  final String relationship;

  final String? date;
  final String? photoUrl;
  final String? linkedinUrl;
  final bool isCTA;
}

abstract final class GalleryTestimonials {
  static const List<Testimonial> all = <Testimonial>[
    Testimonial(
      id: 't1',
      name: 'Ankit Sharma',
      role: 'Engineering Director',
      company: 'Twin Health',
      text: 'Vishal transformed our Flutter platform from a collection of '
          'screens into a true SDK. His architectural instincts are '
          'exceptional — he thinks in systems, not features. The modular '
          'foundation he built powers our entire mobile fleet and has cut '
          'onboarding time for new engineers by half.',
      relationship: 'Managed Vishal',
      date: '2024-11',
    ),
    Testimonial(
      id: 't2',
      name: 'Priya Menon',
      role: 'Senior Product Manager',
      company: 'Twin Health',
      text: 'Working with Vishal was a masterclass in technical partnership. '
          'He never just built what was asked — he challenged assumptions, '
          'proposed elegant alternatives, and delivered solutions that were '
          'both technically sound and user-centric. His AI integration work '
          'was genuinely ahead of its time.',
      relationship: 'Worked with Vishal',
      date: '2024-10',
    ),
    Testimonial(
      id: 't3',
      name: 'Rahul Kapoor',
      role: 'CTO',
      company: 'FieldAssist',
      text: 'Vishal joined us early and grew into one of our most impactful '
          'engineers. He built our offline-first mobile architecture from '
          'scratch — the kind of deep technical work that most engineers shy '
          'away from. His code was clean, his designs were robust, and he '
          'mentored juniors with genuine care.',
      relationship: 'Managed Vishal',
      date: '2022-06',
    ),
    Testimonial(
      id: 't4',
      name: 'Deepak Nair',
      role: 'Lead Backend Engineer',
      company: 'FieldAssist',
      text: 'Rare to find a mobile engineer who truly understands the full '
          'stack. Vishal would often catch API design issues before they '
          'became problems and suggest contract changes that improved both '
          'mobile and backend. His cross-functional thinking made every '
          'project better.',
      relationship: 'Worked with Vishal',
      date: '2022-03',
    ),
    Testimonial(
      id: 't5',
      name: 'Siddharth Jain',
      role: 'VP Engineering',
      company: 'PayU',
      text: "Vishal brought an architect's precision to every mobile project "
          'at PayU. In the payments space, reliability is everything — and '
          'his code reflected that philosophy. He delivered complex payment '
          'flow integrations with clean, maintainable architecture under '
          'tight deadlines.',
      relationship: 'Managed Vishal',
      date: '2019-08',
    ),
    Testimonial(
      id: 't6',
      name: 'Dr. Meera Krishnan',
      role: 'Professor, Computer Science',
      company: 'VIT University',
      text: "Vishal stood out as someone who didn't just complete assignments "
          '— he reimagined them. His final-year project demonstrated a '
          'maturity in software design that I rarely see in undergraduates. '
          'I knew he would go on to build remarkable things.',
      relationship: 'Worked with Vishal',
      date: '2016-05',
    ),
    Testimonial.cta(),
  ];

  /// Real testimonials only — the CTA card renders a form, not a quote.
  static final List<Testimonial> cards =
      all.where((t) => !t.isCTA).toList(growable: false);
}
