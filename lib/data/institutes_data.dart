class Institute {
  final String name;
  final String state; // Using this as Country/Region
  final List<String> courses;
  final String type; // e.g., Ivy League, Russell Group, Global Top 100

  const Institute({
    required this.name,
    required this.state,
    required this.courses,
    required this.type,
  });
}

class InstitutesData {
  static const List<Institute> allInstitutes = [
    // --- USA (Top Universities) ---
    Institute(
      name: 'Harvard University',
      state: 'USA',
      type: 'Ivy League',
      courses: [
        'MBA',
        'MS Computer Science',
        'LLM',
        'PhD Economics',
        'BS Engineering',
        'Masters in Public Policy',
      ],
    ),
    Institute(
      name: 'Massachusetts Institute of Technology (MIT)',
      state: 'USA',
      type: 'Global Top 10',
      courses: [
        'MS Data Science',
        'M.Eng Electrical',
        'MBA (Sloan)',
        'PhD Physics',
        'BS Computer Science',
      ],
    ),
    Institute(
      name: 'Stanford University',
      state: 'USA',
      type: 'Global Top 10',
      courses: [
        'MS Artificial Intelligence',
        'MBA',
        'MS Management',
        'PhD Engineering',
        'BS Symbolic Systems',
      ],
    ),
    Institute(
      name: 'Yale University',
      state: 'USA',
      type: 'Ivy League',
      courses: [
        'MA International Relations',
        'JD Law',
        'MBA',
        'PhD History',
        'BS Biology',
      ],
    ),
    Institute(
      name: 'Princeton University',
      state: 'USA',
      type: 'Ivy League',
      courses: [
        'PhD Mathematics',
        'MA Public Affairs',
        'BSE Engineering',
        'MS Computer Science',
      ],
    ),
    Institute(
      name: 'Columbia University',
      state: 'USA',
      type: 'Ivy League',
      courses: ['MS Journalism', 'MS Finance', 'MBA', 'MS Data Science', 'LLM'],
    ),
    Institute(
      name: 'University of Pennsylvania (UPenn)',
      state: 'USA',
      type: 'Ivy League',
      courses: [
        'MBA (Wharton)',
        'MS Engineering',
        'MS Design',
        'PhD Finance',
        'BS Economics',
      ],
    ),
    Institute(
      name: 'University of California, Berkeley',
      state: 'USA',
      type: 'Public Ivy',
      courses: ['MS CS', 'M.Eng', 'MBA (Haas)', 'PhD Chemistry', 'LLM'],
    ),
    Institute(
      name: 'Carnegie Mellon University (CMU)',
      state: 'USA',
      type: 'Global Top 100',
      courses: [
        'MS Robotics',
        'MS Software Engineering',
        'MS Information Systems',
        'Masters in Entertainment Tech',
      ],
    ),
    Institute(
      name: 'New York University (NYU)',
      state: 'USA',
      type: 'Global Top 100',
      courses: [
        'MS Data Science',
        'MBA (Stern)',
        'MA Film',
        'LLM Law',
        'MS Financial Engineering',
      ],
    ),

    // --- UK (Top Universities) ---
    Institute(
      name: 'University of Oxford',
      state: 'UK',
      type: 'Russell Group',
      courses: [
        'MSc Computer Science',
        'MBA (Saïd)',
        'BA PPE',
        'PhD Medicine',
        'MSc Finance',
      ],
    ),
    Institute(
      name: 'University of Cambridge',
      state: 'UK',
      type: 'Russell Group',
      courses: [
        'MPhil Economics',
        'MBA (Judge)',
        'PhD Physics',
        'BA Mathematics',
        'MSc Engineering',
      ],
    ),
    Institute(
      name: 'Imperial College London',
      state: 'UK',
      type: 'Russell Group',
      courses: [
        'MSc Advanced Computing',
        'MSc Finance',
        'PhD Bioengineering',
        'MBA',
        'BS Physics',
      ],
    ),
    Institute(
      name: 'London School of Economics (LSE)',
      state: 'UK',
      type: 'Russell Group',
      courses: [
        'MSc Finance',
        'MSc Management',
        'MSc Data Science',
        'PhD Sociology',
        'BSc Economics',
      ],
    ),
    Institute(
      name: 'University College London (UCL)',
      state: 'UK',
      type: 'Russell Group',
      courses: [
        'MSc AI',
        'MA Architecture',
        'MSc Management',
        'PhD Education',
        'BSc Psychology',
      ],
    ),
    Institute(
      name: 'University of Edinburgh',
      state: 'UK',
      type: 'Russell Group',
      courses: [
        'MSc Informatics',
        'MBA',
        'MSc Artificial Intelligence',
        'PhD Literature',
      ],
    ),

    // --- Canada (Top Universities) ---
    Institute(
      name: 'University of Toronto',
      state: 'Canada',
      type: 'U15 Group',
      courses: [
        'MS Applied Computing',
        'MBA (Rotman)',
        'M.Eng Civil',
        'PhD Philosophy',
        'BSc Life Sciences',
      ],
    ),
    Institute(
      name: 'University of British Columbia (UBC)',
      state: 'Canada',
      type: 'U15 Group',
      courses: [
        'MS Computer Science',
        'MBA',
        'MS Forestry',
        'PhD Psychology',
        'BS Electrical Eng',
      ],
    ),
    Institute(
      name: 'McGill University',
      state: 'Canada',
      type: 'U15 Group',
      courses: ['MS Neuroscience', 'MBA', 'LLM', 'PhD Physics', 'B.Eng Mining'],
    ),
    Institute(
      name: 'University of Waterloo',
      state: 'Canada',
      type: 'U15 Group',
      courses: [
        'Master of Quantitative Finance',
        'M.Math Computer Science',
        'PhD Actuarial Science',
        'B.SoftEng',
      ],
    ),

    // --- Australia (Top Universities) ---
    Institute(
      name: 'University of Melbourne',
      state: 'Australia',
      type: 'Group of Eight',
      courses: [
        'Master of IT',
        'MBA',
        'Master of Finance',
        'PhD Architecture',
        'BS Biomedicine',
      ],
    ),
    Institute(
      name: 'University of Sydney',
      state: 'Australia',
      type: 'Group of Eight',
      courses: [
        'Master of Data Science',
        'MBA',
        'Master of International Business',
        'PhD Health Sciences',
      ],
    ),
    Institute(
      name: 'Australian National University (ANU)',
      state: 'Australia',
      type: 'Group of Eight',
      courses: [
        'Master of Computing',
        'Master of Strategic Studies',
        'PhD Anthropology',
        'B.PolSci',
      ],
    ),
    Institute(
      name: 'University of New South Wales (UNSW)',
      state: 'Australia',
      type: 'Group of Eight',
      courses: [
        'Master of Engineering',
        'MBA (AGSM)',
        'Master of Finance',
        'PhD Solar Energy',
      ],
    ),

    // --- Europe & Asia ---
    Institute(
      name: 'ETH Zurich',
      state: 'Switzerland',
      type: 'Global Top 10',
      courses: [
        'MS Computer Science',
        'MS Robotics',
        'MSc Quantum Engineering',
        'PhD Mathematics',
      ],
    ),
    Institute(
      name: 'Technical University of Munich (TUM)',
      state: 'Germany',
      type: 'TU9',
      courses: [
        'MSc Informatics',
        'MSc Automotive Engineering',
        'MBA',
        'PhD Aerospace',
      ],
    ),
    Institute(
      name: 'National University of Singapore (NUS)',
      state: 'Singapore',
      type: 'Global Top 20',
      courses: [
        'MS Computing',
        'MBA',
        'MS Supply Chain',
        'PhD Public Policy',
        'BS Business',
      ],
    ),
    Institute(
      name: 'Nanyang Technological University (NTU)',
      state: 'Singapore',
      type: 'Global Top 20',
      courses: [
        'MS AI',
        'MSc Finance',
        'MBA',
        'PhD Engineering',
        'BS Materials Science',
      ],
    ),
    Institute(
      name: 'Delft University of Technology',
      state: 'Netherlands',
      type: 'IDEA League',
      courses: [
        'MSc Aerospace Engineering',
        'MSc Hydraulic Engineering',
        'PhD Urbanism',
      ],
    ),
  ];
}
